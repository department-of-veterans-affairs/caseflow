# frozen_string_literal: true

require "json"

class ExternalApi::EfolderService
  DOCUMENT_COUNT_DEFERRED = -1

  def self.document_count_cache_key(file_number)
    "Efolder-document-count-#{file_number}"
  end

  # spawns asychronous FetchEfolderDocumentCountJob background job
  def self.document_count(file_number, user)
    efolder_doc_count_bgjob_key = "Efolder-document-count-bgjob-#{file_number}"

    # if it's in the cache return it.
    doc_count = Rails.cache.fetch(document_count_cache_key(file_number))
    return doc_count if doc_count

    # if not in the cache, start a bg job to cache it.
    # set flag to indicate we've started bg job so we don't start multiple.
    # give the bg job 15 minutes to complete before starting another.
    Rails.cache.fetch(efolder_doc_count_bgjob_key, expires_in: 15.minutes) do
      FetchEfolderDocumentCountJob.perform_later(file_number: file_number, user: user)
    end

    # indicate to caller to check back later
    DOCUMENT_COUNT_DEFERRED
  end

  # synchronous API call used by the FetchEfolderDocumentCountJob background job
  def self.fetch_document_count(file_number, user)
    Rails.cache.fetch(document_count_cache_key(file_number), expires_in: 4.hours) do
      headers = { "FILE-NUMBER" => file_number }
      response = send_efolder_request("/api/v2/document_counts", user, headers)
      response_body = JSON.parse(response.body)
      response_body["documents"]
    rescue JSON::ParserError => error
      handle_json_parser_error(error, response)
    end
  end

  def self.handle_json_parser_error(error, response)
    if response.code == 502
      # re-throw so we try again, but don't log to sentry.
      fail Caseflow::Error::TransientError, message: response.body, code: response.code
    else
      fail error
    end
  end

  def self.fetch_documents_for(appeal, user)
    generate_efolder_request(appeal.veteran_file_number.to_s, user)
  end

  def self.generate_efolder_request(vbms_id, user, retry_attempts_count = 10)
    headers = { "FILE-NUMBER" => vbms_id }
    response = send_efolder_request("/api/v2/manifests", user, headers, method: :post)
    response_attrs = {}

    retry_attempts_count.times do
      response_body = JSON.parse(response.body)

      check_for_error(response_body: response_body, code: response.code, vbms_id: vbms_id, user_id: user.id)

      response_attrs = response_body["data"]["attributes"]
      if response_attrs["sources"].select { |s| s["status"] == "pending" }.blank?
        return generate_response(response_attrs, vbms_id)
      end

      sleep 1
      manifest_id = response_body["data"]["id"]
      response = send_efolder_request("/api/v2/manifests/#{manifest_id}", user, headers)
    end

    generate_response(response_attrs, vbms_id)
  end

  def self.check_for_error(response_body:, code:, vbms_id:, user_id:)
    case code
    when 200
      if response_body["data"]["attributes"]["sources"].blank?
        msg = "Failed for #{vbms_id}, manifest sources are blank"
        fail Caseflow::Error::DocumentRetrievalError, code: 502, message: msg
      end
    when 403
      fail Caseflow::Error::EfolderAccessForbidden, code: code, message: response_body
    when 400
      fail Caseflow::Error::ClientRequestError, code: code, message: response_body
    when 500
      fail Caseflow::Error::DocumentRetrievalError, code: 502, message: response_body
    else
      msg = "Failed for #{vbms_id}, user_id: #{user_id}, error: #{response_body}, HTTP code: #{code}"
      fail Caseflow::Error::DocumentRetrievalError, code: 502, message: msg
    end
  end

  def self.generate_response(response_attrs, vbms_id)
    documents = response_attrs["records"] || []
    Rails.logger.info("# of Records retrieved from efolder v2: #{documents.length}")

    vbms_status = response_attrs["sources"].find { |s| s["source"] == "VBMS" }
    vva_status = response_attrs["sources"].find { |s| s["source"] == "VVA" }

    {
      manifest_vbms_fetched_at: vbms_status.present? ? vbms_status["fetched_at"] : nil,
      manifest_vva_fetched_at: vva_status.present? ? vva_status["fetched_at"] : nil,
      documents: documents.map { |efolder_document| Document.from_efolder(efolder_document, vbms_id) }
    }
  end

  def self.efolder_content_url(id)
    URI(efolder_base_url + "/api/v2/records/#{id}").to_s
  end

  def self.efolder_base_url
    Rails.application.config.efolder_url.to_s
  end

  def self.efolder_key
    Rails.application.config.efolder_key.to_s
  end

  def self.send_efolder_request(endpoint, user, headers = {}, method: :get)
    DBService.release_db_connections

    url = URI::DEFAULT_PARSER.escape(efolder_base_url + endpoint)
    request = HTTPI::Request.new(url)
    request.open_timeout = 600 # seconds
    request.read_timeout = 600 # seconds
    request.auth.ssl.ssl_version  = :TLSv1_2
    request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]

    headers["AUTHORIZATION"] = "Token token=#{efolder_key}"
    headers["CSS-ID"] = user.css_id.to_s
    headers["STATION-ID"] = user.station_id.to_s
    request.headers = headers
    MetricsService.record("eFolder GET request to #{url}",
                          service: :efolder,
                          name: "/api/#{endpoint.split('/')[2]}/#{endpoint.split('/')[3]}") do
      case method
      when :get
        HTTPI.get(request)
      when :post
        HTTPI.post(request)
      end
    end
  end
end
