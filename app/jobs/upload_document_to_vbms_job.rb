# frozen_string_literal: true

class UploadDocumentToVbmsJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :idt

  def perform(document_id:, initiator_css_id:)
    RequestStore.store[:application] = "idt"
    RequestStore.store[:current_user] = User.system_user

    @document = VbmsUploadedDocument.find_by(id: document_id)
    @initiator = User.find_by_css_id(initiator_css_id)
    add_context_to_sentry
    UploadDocumentToVbms.new(document: document).call
  end

  private

  attr_reader :document, :initiator

  def add_context_to_sentry
    if initiator.present?
      Raven.user_context(
        email: initiator.email,
        css_id: initiator.css_id,
        station_id: initiator.station_id,
        regional_office: initiator.regional_office
      )
    end
    Raven.extra_context(
      vbms_uploaded_document_id: document.id,
      case_details_path: "/queue/appeals/#{document.appeal.external_id}"
    )
  end
end
