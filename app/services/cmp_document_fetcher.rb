# frozen_string_literal: true

class CmpDocumentFetcher
  def get_cmp_document_content(cmp_document_uuid)
    return fetched_doc_contents[cmp_document_uuid] if fetched_doc_contents.key?(cmp_document_uuid)

    doc_content = nil

    begin
      doc_content = vefs_api_client.fetch_cmp_document_content_by_uuid(cmp_document_uuid)
    rescue StandardError => error
      Rails.logger.error(error)
      vefs_error_handler.handle_error(error: error, error_details: {})
    end

    if doc_content.present?
      fetched_doc_contents[cmp_document_uuid] = doc_content
    end

    doc_content
  end

  private

  def vefs_api_client
    @vefs_api_client ||= ExternalApi::VefsApiClient.new
  end

  def vefs_error_handler
    @vefs_error_handler ||= ErrorHandlers::VefsApiErrorHandler.new
  end

  def fetched_doc_contents
    @fetched_doc_contents ||= {}
  end
end
