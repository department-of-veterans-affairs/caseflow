# frozen_string_literal: true

class UpdateDocumentInVbms
  include VbmsDocumentTransactionConcern

  delegate :document_type, :document_subject, :document_name, :document_version_reference_id, to: :document

  def initialize(document:)
    @document = document
  end

  def call
    return if document.processed_at

    submit_for_processing!
    update_in_vbms!
    set_processed_at_to_current_time
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

  def update_in_vbms!
    return if document.uploaded_to_vbms_at

    update_response = VBMSService.update_document_in_vbms(document.appeal, self)

    persist_efolder_version_info(update_response, :update_document_response)

    document.update!(uploaded_to_vbms_at: Time.zone.now)
  end
end
