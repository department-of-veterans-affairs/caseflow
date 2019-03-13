# frozen_string_literal: true

class UploadDocumentToVbmsJob < CaseflowJob
  queue_as :low_priority
  application_attr :idt

  def perform(document:, file:)
    RequestStore.store[:application] = "idt"
    RequestStore.store[:current_user] = User.system_user

    UploadDocumentToVbms.new(document: document, file: file).call
  end
end
