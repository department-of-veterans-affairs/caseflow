require "HTTPI"
require "json"

class ExternalApi::EfolderService
  def self.fetch_document_file(user, document)
    # Makes a GET request to https://<efolder_url>/documents/<efolder_id>
    uri = URI.escape(efolder_base_url + "/api/v1/documents/" + document.efolder_id.to_s)
    response = get_efolder_response(uri, user)

    Rails.logger.error "Could not retrieve document from efolder for document: #{document}" if response.error?
    fail Caseflow::Error::DocumentRetrievalError if response.error?

    response.raw_body
  end

  def self.fetch_documents_for(user, appeal)
    # Makes a GET request to https://<efolder_url>/files/<file_number>
    headers = { "FILE-NUMBER" => appeal.sanitized_vbms_id.to_s }
    response = get_efolder_response(efolder_base_url + "/files", user, headers)

    Rails.logger.error "Could not retrieve files from efolder for appeal: #{appeal}" if response.error?
    fail Caseflow::Error::DocumentRetrievalError if response.error?

    documents = JSON.parse(response.body)["data"]
    Rails.logger.info("# of Documents retrieved from efolder: #{documents.length}")

    documents.map { |efolder_document| Document.from_efolder(efolder_document) }
  end

  def self.efolder_base_url
    Rails.application.config.efolder_url.to_s
  end

  def self.efolder_key
    Rails.application.config.efolder_key.to_s
  end

  def self.get_efolder_response(url, user, headers = {})
    response = []

    url = URI.escape(url)
    MetricsService.record "eFolder GET request to #{url}" do
      request = HTTPI::Request.new(url)

      headers["AUTHORIZATION"] = "Token token=#{efolder_key}"
      headers["CSS-ID"] = user.css_id.to_s
      headers["STATION-ID"] = user.station_id.to_s
      request.headers = headers

      response = HTTPI.get(request)
    end

    Rails.logger.error "Error sending request to eFolder: #{url}. HTTP Status Code: #{response.code}" if response.error?

    response
  end
end
