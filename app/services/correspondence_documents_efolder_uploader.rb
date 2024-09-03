# frozen_string_literal: true

class CorrespondenceDocumentsEfolderUploader
  def upload_documents_to_claim_evidence(correspondence, current_user, parent_task)
    if Rails.env.production?
      do_upload(correspondence)

      true
    elsif FeatureToggle.enabled?(:ce_api_demo_toggle)
      if Rails.env.test?
        do_upload(correspondence)
      end

      true
    else
      fail "Mock failure for upload in non-prod env"
    end
  rescue StandardError => error
    Rails.logger.error(error.full_message)

    params_hash = {
      correspondence: correspondence, current_user: current_user,
      parent_task: parent_task, reason: error.full_message
    }
    create_efolder_upload_failed_task(params_hash)

    false
  end

  private

  def corresondence_veteran(correspondence)
    Veteran.find_by(id: correspondence.veteran_id)
  end

  def create_efolder_upload_failed_task(args)
    correspondence = args[:correspondence]
    current_user = args[:current_user]
    parent_task = args[:parent_task]
    reason = args[:reason]

    return if EfolderUploadFailedTask.where(appeal_id: correspondence.id).count > 0

    euft = EfolderUploadFailedTask.find_or_create_by(
      appeal_id: correspondence.id,
      appeal_type: Correspondence.name,
      type: EfolderUploadFailedTask.name,
      assigned_to: current_user,
      parent_id: parent_task.id,
      instructions: [reason]
    )

    euft.update!(status: Constants.TASK_STATUSES.in_progress)
  end

  # :reek:FeatureEnvy
  def do_upload(correspondence)
    correspondence.correspondence_documents.each do |doc|
      ExternalApi::ClaimEvidenceService.upload_document(
        doc.pdf_location,
        corresondence_veteran(correspondence).file_number,
        doc.claim_evidence_upload_hash
      )
    end
  end
end
