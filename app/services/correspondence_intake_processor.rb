# frozen_string_literal: true

class CorrespondenceIntakeProcessor
  def process_intake(intake_params, current_user)
    correspondence = Correspondence.find_by(uuid: intake_params[:correspondence_uuid])

    fail "Correspondence not found" if correspondence.blank?

    success = true

    ActiveRecord::Base.transaction do
      begin
        create_correspondence_relations(intake_params, correspondence.id)
        link_appeals_to_correspondence(intake_params, correspondence.id)
        add_tasks_to_related_appeals(intake_params, current_user)
        complete_waived_evidence_submission_tasks(intake_params)
        create_tasks_not_related_to_appeals(intake_params, correspondence, current_user)
        create_mail_tasks(intake_params, correspondence, current_user)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        success = false
        raise ActiveRecord::Rollback
      end
    end

    success
  end

  def upload_documents_to_claim_evidence(correspondence, current_user)
    if Rails.env.development? || Rails.env.demo? || Rails.env.test?
      true
    else
      begin
        correspondence.correspondence_documents.all.each do |doc|
          ExternalApi::ClaimEvidenceService.upload_document(
            doc.pdf_location,
            veteran_by_correspondence.file_number,
            doc.claim_evidence_upload_json
          )
        end

        true
      rescue StandardError => error
        Rails.logger.error(error.to_s)
        create_efolder_upload_failed_task(correspondence, current_user)

        false
      end
    end
  end

  private

  def create_correspondence_relations(intake_params, correspondence_id)
    intake_params[:related_correspondence_uuids]&.map do |uuid|
      CorrespondenceRelation.create!(
        correspondence_id: correspondence_id,
        related_correspondence_id: Correspondence.find_by(uuid: uuid)&.id
      )
    end
  end

  def link_appeals_to_correspondence(intake_params, correspondence_id)
    intake_params[:related_appeal_ids]&.map do |appeal_id|
      CorrespondencesAppeal.find_or_create_by(correspondence_id: correspondence_id, appeal_id: appeal_id)
    end
  end

  def add_tasks_to_related_appeals(intake_params, current_user)
    intake_params[:tasks_related_to_appeal]&.map do |data|
      appeal = Appeal.find(data[:appeal_id])

      class_for_data(data).create_from_params(
        {
          appeal: appeal,
          parent_id: appeal.root_task&.id,
          assigned_to: data[:assigned_to].constantize.singleton,
          instructions: data[:content]
        }, current_user
      )
    end
  end

  def complete_waived_evidence_submission_tasks(intake_params)
    intake_params[:waived_evidence_submission_window_tasks]&.map do |task|
      evidence_submission_window_task = EvidenceSubmissionWindowTask.find(task[:task_id])
      instructions = evidence_submission_window_task.instructions
      evidence_submission_window_task.when_timer_ends
      evidence_submission_window_task.update!(instructions: (instructions << task[:waive_reason]))
    end
  end

  def create_efolder_upload_failed_task(correspondence, current_user)
    rpt = ReviewPackageTask.find_by(appeal_id: correspondence.id, type: ReviewPackageTask.name)

    euft = EfolderUploadFailedTask.find_or_create_by(
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      type: EfolderUploadFailedTask.name,
      assigned_to: current_user,
      parent_id: rpt.id
    )

    euft.update!(status: Constants.TASK_STATUSES.in_progress)
  end

  def create_tasks_not_related_to_appeals(intake_params, correspondence, current_user)
    unrelated_task_data = intake_params[:tasks_not_related_to_appeal]

    return if unrelated_task_data.blank? || !unrelated_task_data.length

    unrelated_task_data.map do |data|
      class_for_data(data).create_from_params(
        {
          parent_id: correspondence.root_task.id,
          assigned_to: data[:assigned_to].constantize.singleton,
          instructions: data[:content]
        }, current_user
      )
    end
  end

  def create_mail_tasks(intake_params, correspondence, current_user)
    mail_task_data = intake_params[:mail_tasks]

    return if mail_task_data.blank? || !mail_task_data.length

    mail_task_data.map do |mail_task_type|
      task = mail_task_class_for_type(mail_task_type).create_from_params(
        {
          parent_id: correspondence.root_task.id,
          assigned_to_id: current_user.id,
          assigned_to_type: User.name
        }, current_user
      )

      task.update!(status: Constants.TASK_STATUSES.completed)
    end
  end

  def mail_task_class_for_type(task_type)
    task_types = {
      "Associated with Claims Folder": AssociatedWithClaimsFolderMailTask.name,
      "Change of address": AddressChangeMailTask.name,
      "Evidence or argument": EvidenceOrArgumentMailTask.name,
      "Returned or undeliverable mail": ReturnedUndeliverableCorrespondenceMailTask.name,
      "Sent to ROJ": SentToRojMailTask.name,
      "VACOLS updated": VacolsUpdatedMailTask.name
    }.with_indifferent_access

    task_types[task_type]&.constantize
  end

  def class_for_data(data)
    data[:klass]&.constantize
  end
end
