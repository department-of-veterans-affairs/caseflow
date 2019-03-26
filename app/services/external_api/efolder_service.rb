# frozen_string_literal: true

require "json"

class ExternalApi::EfolderService
  TRIES = 300

  def self.fetch_documents_for(appeal, user)
    generate_efolder_request(appeal.veteran_file_number.to_s, user)
  end

  def self.generate_efolder_request(vbms_id, user)
    headers = { "FILE-NUMBER" => vbms_id }
    response = send_efolder_request("/api/v2/manifests", user, headers, method: :post)
    response_attrs = {}

    TRIES.times do
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

    msg = "Failed to fetch manifest after #{TRIES} seconds for #{vbms_id}, \
      user_id: #{user.id}, response attributes: #{response_attrs}"
    fail Caseflow::Error::DocumentRetrievalError, code: 504, message: msg
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

  # rubocop:disable Metrics/MethodLength
  def self.send_efolder_request(endpoint, user, headers = {}, method: :get)
    DBService.release_db_connections

    url = URI.escape(efolder_base_url + endpoint)
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
  # rubocop:enable Metrics/MethodLength
end
