# frozen_string_literal: true

class ExternalApi::VbmsDocumentsForAppeal < ExternalApi::VbmsRequestWithFileNumber
  def fetch
    @documents = request_with_retry

    Rails.logger.info("Document list length: #{documents.length}")

    result_hash
  end

  protected

  def do_request(ssn_or_claim_number)
    if FeatureToggle.enabled?(:vbms_pagination, user: RequestStore[:current_user])
      ExternalApi::VBMSService.call_and_log_service(
        service: vbms_paged_documents_service,
        vbms_id: ssn_or_claim_number
      )&.[](:documents) || []
    else
      vbms_request = VBMS::Requests::FindDocumentVersionReference.new(ssn_or_claim_number)

      ExternalApi::VBMSRequest.new(
        client: vbms_client,
        request: vbms_request,
        id: ssn_or_claim_number
      ).call
    end
  end

  private

  attr_reader :documents

  def vbms_paged_documents_service
    @vbms_paged_documents_service ||= VBMS::Service::PagedDocuments.new(client: vbms_client)
  end

  def result_hash
    {
      manifest_vbms_fetched_at: nil,
      manifest_vva_fetched_at: nil,
      documents: DocumentsFromVbmsDocuments.new(documents: documents, file_number: file_number).call
    }
  end
end
