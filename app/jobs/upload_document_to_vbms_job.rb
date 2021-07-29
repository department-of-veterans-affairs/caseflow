# frozen_string_literal: true

class UploadDocumentToVbmsJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :idt

  def perform(document_id:)
    RequestStore.store[:application] = "idt"
    RequestStore.store[:current_user] = User.system_user

    @document = VbmsUploadedDocument.find_by(id: document_id)
    add_extra_context_to_sentry
    UploadDocumentToVbms.new(document: document).call
  end

  private

  attr_reader :document

  def add_extra_context_to_sentry
    Raven.extra_context(
      vbms_uploaded_document_id: document.id,
      case_details_path: "/queue/appeals/#{document.appeal.external_id}"
    )
  end
end
