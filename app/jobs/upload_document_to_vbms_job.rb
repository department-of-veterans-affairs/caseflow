# frozen_string_literal: true

class UploadDocumentToVbmsJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :idt

  def perform(document_id:)
    RequestStore.store[:application] = "idt"
    RequestStore.store[:current_user] = User.system_user

    document = VbmsUploadedDocument.find_by(id: document_id)
    UploadDocumentToVbms.new(document: document).call
  end
end
