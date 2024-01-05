# frozen_string_literal: true

class CorrespondenceDocumentsEfolderUploader
  def upload_documents_to_claim_evidence(correspondence, current_user, parent_task)
    if Rails.env.production?
      do_upload(correspondence)

      true
    else
      if FeatureToggle.enabled?(:ce_api_demo_toggle)
        if Rails.env.test?
          do_upload(correspondence)
        end

        true
      else
        fail "Mock failure for upload in non-prod env"
      end
    end
  rescue StandardError => error
    Rails.logger.error(error.to_s)
    create_efolder_upload_failed_task(correspondence, current_user, parent_task)

    false
  end

  private

  def corresondence_veteran(correspondence)
    Veteran.find_by(id: correspondence.veteran_id)
  end

  def create_efolder_upload_failed_task(correspondence, current_user, parent_task)
    euft = EfolderUploadFailedTask.find_or_create_by(
      appeal_id: correspondence.id,
      appeal_type: Correspondence.name,
      type: EfolderUploadFailedTask.name,
      assigned_to: current_user,
      parent_id: parent_task.id
    )

    euft.update!(status: Constants.TASK_STATUSES.in_progress)
  end

  def do_upload(correspondence)
    correspondence.correspondence_documents.each do |doc|
      ExternalApi::ClaimEvidenceService.upload_document(
        doc.pdf_location,
        corresondence_veteran(correspondence).file_number,
        doc.claim_evidence_upload_json
      )
    end
  end
end
