require "HTTPI"
require "json"

class ExternalApi::EfolderService
  def self.fetch_document_file(user, document)
    # Makes a GET request to https://<efolder_url>/documents/<efolder_id>
    response = MetricsService.record("eFolder GET document request for ID: #{document.efolder_id}",
                                     service: :efolder,
                                     name: "/api/v1/documents") do
      get_efolder_response("/api/v1/documents/" + document.efolder_id.to_s, user)
    end

    Rails.logger.error "eFolder HTTP status code: #{response.code} for document: #{document}" if response.error?
    fail Caseflow::Error::DocumentRetrievalError if response.error?

    response.raw_body
  end

  def self.fetch_documents_for(user, appeal)
    # Makes a GET request to https://<efolder_url>/files/<file_number>
    headers = { "FILE-NUMBER" => appeal.sanitized_vbms_id.to_s }
    response = MetricsService.record("eFolder GET files request for VBMS ID: #{appeal.sanitized_vbms_id}",
                                     service: :efolder,
                                     name: "/api/v1/files") do
      get_efolder_response("/api/v1/files", user, headers)
    end

    Rails.logger.error "eFolder HTTP status code: #{response.code} for appeal: #{appeal}. " if response.error?
    fail Caseflow::Error::DocumentRetrievalError if response.error?

    documents = JSON.parse(response.body).try(:[], "data").try(:[], "attributes").try(:[], "documents") || []
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

    headers["AUTHORIZATION"] = "Token token=#{efolder_key}"
    headers["CSS-ID"] = user.css_id.to_s
    headers["STATION-ID"] = user.station_id.to_s
    request.headers = headers

    HTTPI.get(request)
  end
end
