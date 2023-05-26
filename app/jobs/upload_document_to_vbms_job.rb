# frozen_string_literal: true

class UploadDocumentToVbmsJob < CaseflowJob
  queue_with_priority :low_priority

  # Purpose: Calls the UploadDocumentToVbms workflow to upload the given document to VBMS
  #
  # Params: document_id - integer to search for VbmsUploadedDocument
  #         initiator_css_id - string to find a user by css_id
  #         application - string with a default value of "idt" but can be overwritten
  #         mail_request - MailRequest object with recipient/address info to be sent to Package Manager (optional)
  #
  # Return: nil
  def perform(document_id:, initiator_css_id:, mail_requests: [], application: "idt")
    RequestStore.store[:application] = application
    RequestStore.store[:current_user] = User.system_user

    @document = VbmsUploadedDocument.find_by(id: document_id)
    @initiator = User.find_by_css_id(initiator_css_id)
    add_context_to_sentry
    UploadDocumentToVbms.new(document: document).call
    queue_mail_request_job(mail_requests) unless mail_requests.empty?
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
      upload_document_path: "/upload_document",
      veteran_file_number: document.veteran_file_number
    )
  end

  def queue_mail_request_job(mail_requests)
    return unless document.uploaded_to_vbms_at

    MailRequestJob.perform_later(document, mail_requests)
    status = "MailRequestJob queued for submission to Package Manager"
    log_info(document: document, mail_request: mail_request, status: status)
  end

  def log_info(info_message)
    uuid = SecureRandom.uuid
    Rails.logger.info(info_message + "ID: " + uuid)
  end
end
