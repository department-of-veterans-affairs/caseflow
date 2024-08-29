# frozen_string_literal: true

class UploadDocumentToVbms
  include VbmsDocumentTransactionConcern

  delegate :document_type, :document_subject, :document_name, to: :document

  def initialize(document:)
    @document = document
  end

  def call
    return if document.processed_at

    submit_for_processing!
    upload_to_vbms!
    set_processed_at_to_current_time
    log_info("Document #{document.id} uploaded to VBMS")
  rescue StandardError => error
    save_rescued_error!(error.to_s)
    raise error
  ensure
    cleanup_up_file
  end

  private

  attr_reader :document

  def submit_for_processing!
    when_to_start = Time.zone.now

    document.update!(
      last_submitted_at: when_to_start,
      submitted_at: when_to_start,
      processed_at: nil,
      attempted_at: when_to_start
    )
  end

  def upload_to_vbms!
    return if document.uploaded_to_vbms_at

    upload_response = VBMSService.upload_document_to_vbms_veteran(file_number, self)

    persist_efolder_version_info(upload_response, :upload_document_response)

    document.update!(uploaded_to_vbms_at: Time.zone.now)
  end
end
