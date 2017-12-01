require "json"

class ExternalApi::EfolderService
  def self.fetch_documents_for(appeal, user)
    # Makes a GET request to https://<efolder_url>/files/<file_number>
    # to return the list of documents associated with the appeal
    sanitized_vbms_id = if Rails.application.config.use_efolder_locally && appeal.vbms_id =~ /DEMO/
                          # If testing against a local eFolder express instance then we want to pass DEMO
                          # values, so we should not sanitize the vbms_id.
                          appeal.vbms_id.to_s
                        else
                          appeal.sanitized_vbms_id.to_s
                        end

    headers = { "FILE-NUMBER" => sanitized_vbms_id }
    response = get_efolder_response("/api/v1/files?download=true", user, headers)

    Rails.logger.error "eFolder HTTP status code: #{response.code} for appeal: #{appeal}. " if response.error?
    fail Caseflow::Error::DocumentRetrievalError if response.error?

    documents = JSON.parse(response.body)["data"]["attributes"]["documents"] || []
    Rails.logger.info("# of Documents retrieved from efolder: #{documents.length}")

    documents.map { |efolder_document| Document.from_efolder(efolder_document) }
  end

  def self.efolder_base_url
    Rails.application.config.efolder_url.to_s
  end

  def self.efolder_key
    Rails.application.config.efolder_key.to_s
  end

  def self.get_efolder_response(endpoint, user, headers = {})
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
      HTTPI.get(request)
    end
  end
end
