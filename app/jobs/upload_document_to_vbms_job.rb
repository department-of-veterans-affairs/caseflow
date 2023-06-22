# frozen_string_literal: true

class UploadDocumentToVbmsJob < CaseflowJob
  queue_with_priority :low_priority

  # Purpose: Calls the UploadDocumentToVbms workflow to upload the given document to VBMS
  #
  # Params: document_id - integer to search for VbmsUploadedDocument
  #         initiator_css_id - string to find a user by css_id
  #         application - string with a default value of "idt" but can be overwritten
  #         mail_package - Payload with distributions value (array of JSON-formatted MailRequest objects),
  #                        copies value (integer), and created_by_id value (integer) to be submitted to
  #                        Package Manager if optional recipient info is present
  #
  # Return: nil
  def perform(params)
    @params = params
    RequestStore.store[:application] = application
    RequestStore.store[:current_user] = User.system_user
    @document = VbmsUploadedDocument.find_by(id: params[:document_id])
    @initiator = User.find_by_css_id(params[:initiator_css_id])
    add_context_to_sentry
    UploadDocumentToVbms.new(document: document).call
    queue_mail_request_job(mail_package) unless mail_package.nil?
  end

  private

  attr_reader :document, :initiator, :params

  def application
    return "idt" if params[:application].blank?

    params[:application]
  end

  def mail_package
    return nil if params[:mail_package].blank?

    params[:mail_package]
  end

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

  def queue_mail_request_job(mail_package)
    return unless document.uploaded_to_vbms_at

    MailRequestJob.perform_later(document, mail_package)
    info_message = "MailRequestJob for document #{document.id} queued for submission to Package Manager"
    log_info(info_message)
  end

  def log_info(info_message)
    uuid = SecureRandom.uuid
    Rails.logger.info(info_message + " ID: " + uuid)
  end
end
