require "HTTPI"

class ExternalApi::EfolderService
  class << self
    attr_accessor :document_records
    attr_accessor :end_product_claim_id
    attr_accessor :uploaded_form8, :uploaded_form8_appeal
  end

  def self.fetch_document_file(document)
    # Makes a GET request to <efolder>/documents/<vbms_doc_id>
    @efolder_client ||= init_vbms_client

    vbms_id = document.vbms_document_id
    uri = URI.escape(efolder_base_url + "/files/" + vbms_id)
    result = get_efolder_response(uri)
    result && result.content
  end

  def self.fetch_documents_for(appeal)
    # Makes a GET request to <efolder>/files/<vbms_id>
    @vbms_client ||= init_vbms_client

    sanitized_id = appeal.sanitized_vbms_id
    uri = URI.escape(efolder_base_url + "/documents/" + sanitized_id)
    documents = get_efolder_response(uri)

    Rails.logger.info("# of Documents retrieved from efolder: #{documents.length}")

    documents.map do |vbms_document|
      Document.from_vbms_document(vbms_document)
    end
  end

  def self.efolder_base_url
    Rails.application.config.efolder_url
  end

  def self.get_efolder_response(url)
    response = []

    MetricsService.record("sent efolder GET request to #{url}",
                          service: :efolder,
                          id: id) do
      request = HTTPI::Request.new(url)
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
