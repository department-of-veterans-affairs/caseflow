require "HTTPI"

class ExternalApi::EfolderService

  def self.fetch_document_file(document)
    # Makes a GET request to <efolder>/documents/<vbms_doc_id>
    uri = URI.escape(efolder_base_url + "/documents/" + document.vbms_document_id)
    result = get_efolder_response(uri)
    result && result.content
  end

  def self.fetch_documents_for(appeal)
    # Makes a GET request to <efolder>/files/<file_number>
    uri = URI.escape(efolder_base_url + "/files")

    headers = { "HTTP-FILE-NUMBER" => appeal.veteran.file_number }
    documents = get_efolder_response(uri, headers)

    Rails.logger.info("# of Documents retrieved from efolder: #{documents.length}")

    documents.map do |vbms_document|
      Document.from_vbms_document(vbms_document)
    end
  end

  def self.efolder_base_url
    Rails.application.config.efolder_url
  end

  def self.efolder_token
    Rails.application.config.efolder_token
  end

  def self.get_efolder_response(url, headers = {})
    response = []

    MetricsService.record("sent efolder GET request to #{url}",
                          service: :efolder,
                          id: id) do
      request = HTTPI::Request.new(url)

      headers["HTTP-AUTHORIZATION"] = "Token token=#{efolder_token}"
      request.headers = headers

      response = request.get
    end

    if response.error?
      Rails.logger.error "Error sending request to eFolder: #{url}. HTTP Status Code: #{response.code}"
    else
      response = response.body
    end

    response
  end
end
