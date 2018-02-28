require "json"

class ExternalApi::EfolderService
  TRIES = 20

  def self.fetch_documents_for(appeal, user)
    # Makes a GET request to https://<efolder_url>/files/<file_number>
    # to return the list of documents associated with the appeal
    return efolder_v2_api(appeal.sanitized_vbms_id.to_s, user) if FeatureToggle.enabled?(:efolder_api_v2, user: user)
    efolder_v1_api(appeal.sanitized_vbms_id.to_s, user)
  end

  def self.efolder_v1_api(vbms_id, user)
    headers = { "FILE-NUMBER" => vbms_id }

    response = send_efolder_request("/api/v1/files?download=true", user, headers)

    if response.error?
      fail Caseflow::Error::EfolderAccessForbidden, "403" if response.try(:code) == 403
      fail Caseflow::Error::DocumentRetrievalError, "502" if response.try(:code) == 500
      fail Caseflow::Error::DocumentRetrievalError, response.code.to_s
    end

    response_attrs = JSON.parse(response.body)["data"]["attributes"]

    documents = response_attrs["documents"] || []
    Rails.logger.info("# of Documents retrieved from efolder v1: #{documents.length}")

    {
      manifest_vbms_fetched_at: response_attrs["manifest_vbms_fetched_at"],
      manifest_vva_fetched_at: response_attrs["manifest_vva_fetched_at"],
      documents: documents.map { |efolder_document| Document.from_efolder(efolder_document, vbms_id) }
    }
  end

  def self.efolder_v2_api(vbms_id, user)
    headers = { "FILE-NUMBER" => vbms_id }

    response_attrs = {}

    response = send_efolder_request("/api/v2/manifests", user, headers, method: :post)
    # binding.pry
    TRIES.times do
      fail Caseflow::Error::DocumentRetrievalError if response.error?

      response_attrs = JSON.parse(response.body)["data"]["attributes"]

      fail Caseflow::Error::DocumentRetrievalError if response_attrs["sources"].blank?

      break if response_attrs["sources"].select { |s| s["status"] == "pending" }.blank?
      sleep 1
      manifest_id = response_attrs["id"]
      response = send_efolder_request("/api/v2/manifests/#{manifest_id}", user, headers)
    end

    generate_response(response_attrs, vbms_id)
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

  def self.efolder_files_url
    # TODO: support v2
    URI(efolder_base_url + "/api/v1/files").to_s
  end

  def self.efolder_content_url(id)
    if FeatureToggle.enabled?(:efolder_api_v2, user: RequestStore.store[:current_user])
      URI(efolder_base_url + "/api/v2/records/#{id}").to_s
    else
      URI(efolder_base_url + "/api/v1/documents/#{id}").to_s
    end
  end

  def self.efolder_base_url
    Rails.application.config.efolder_url.to_s
  end

  def self.efolder_key
    Rails.application.config.efolder_key.to_s
  end

  def self.send_efolder_request(endpoint, user, headers = {}, method: :get)
    DBService.release_db_connections

    url = URI.escape(efolder_base_url + endpoint)
    request = HTTPI::Request.new(url)
    request.auth.ssl.ssl_version  = :TLSv1_2
    request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]

    headers["AUTHORIZATION"] = "Token token=#{efolder_key}"
    headers["CSS-ID"] = user.css_id.to_s
    headers["STATION-ID"] = user.station_id.to_s
    request.headers = headers
    MetricsService.record("eFolder GET request to #{url}",
                          service: :efolder,
                          name: endpoint) do
      case method
      when :get
        HTTPI.get(request)
      when :post
        HTTPI.post(request)
      end
    end
  end
end
