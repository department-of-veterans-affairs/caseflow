# frozen_string_literal: true

# :reek:DataClump
# :reek:FeatureEnvy
class CorrespondenceIntakeProcessor
  def process_intake(intake_params, current_user)
    correspondence = Correspondence.find_by(uuid: intake_params[:correspondence_uuid])

    fail "Correspondence not found" if correspondence.blank?

    parent_task = CorrespondenceIntakeTask.find_by(appeal_id: correspondence.id, type: CorrespondenceIntakeTask.name)

    return false if !correspondence_documents_efolder_uploader.upload_documents_to_claim_evidence(
      correspondence,
      current_user,
      parent_task
    )

    do_upload_success_actions(parent_task, intake_params, correspondence, current_user)
  end

  private

  # :reek:LongParameterList
  def do_upload_success_actions(parent_task, intake_params, correspondence, current_user)
    ActiveRecord::Base.transaction do
      parent_task.update!(status: Constants.TASK_STATUSES.completed)

      create_correspondence_relations(intake_params, correspondence.id)
      link_appeals_to_correspondence(intake_params, correspondence.id)
      create_response_letter(intake_params, correspondence.id)
      add_tasks_to_related_appeals(intake_params, current_user)
      complete_waived_evidence_submission_tasks(intake_params)
      create_tasks_not_related_to_appeals(intake_params, correspondence, current_user)
      create_mail_tasks(intake_params, correspondence, current_user)
    end

    true
  rescue StandardError => error
    Rails.logger.error(error.full_message)

    false
  end

  def create_correspondence_relations(intake_params, correspondence_id)
    intake_params[:related_correspondence_uuids]&.map do |uuid|
      CorrespondenceRelation.create!(
        correspondence_id: correspondence_id,
        related_correspondence_id: Correspondence.find_by(uuid: uuid)&.id
      )
    end
  end

  def create_response_letter(intake_params, correspondence_id)

    intake_params[:response_letters]&.map do |data|
      CorrespondenceResponseLetter.create!(
        correspondence_id: correspondence_id,
        date_sent: data[:date],
        title: data[:title],
        subcategory: data[:subType],
        reason: data[:reason],
        response_window: data[:responseWindows]
        letter_type: data[:type]
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
          assigned_to: class_for_assigned_to(data[:assigned_to]).singleton,
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

  def create_tasks_not_related_to_appeals(intake_params, correspondence, current_user)
    unrelated_task_data = intake_params[:tasks_not_related_to_appeal]

    return if unrelated_task_data.blank? || !unrelated_task_data.length

    unrelated_task_data.map do |data|
      class_for_data(data).create_from_params(
        {
          parent_id: correspondence.root_task.id,
          assigned_to: class_for_assigned_to(data[:assigned_to]).singleton,
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

  def class_for_data(data)
    task_class_for_type(data[:klass])
  end

  def correspondence_documents_efolder_uploader
    @correspondence_documents_efolder_uploader ||= CorrespondenceDocumentsEfolderUploader.new
  end

  def mail_task_class_for_type(task_type)
    mail_task_types = {
      "Associated with Claims Folder": AssociatedWithClaimsFolderMailTask.name,
      "Change of address": AddressChangeMailTask.name,
      "Evidence or argument": EvidenceOrArgumentMailTask.name,
      "Returned or undeliverable mail": ReturnedUndeliverableCorrespondenceMailTask.name,
      "Sent to ROJ": SentToRojMailTask.name,
      "VACOLS updated": VacolsUpdatedMailTask.name
    }.with_indifferent_access

    mail_task_types[task_type]&.constantize
  end

  # rubocop:disable Metrics/MethodLength
  def task_class_for_type(task_type)
    task_types = {
      "AddressChangeMailTask": AddressChangeMailTask.name,
      "AodMotionMailTask": AodMotionMailTask.name,
      "AppealWithdrawalMailTask": AppealWithdrawalMailTask.name,
      "CavcCorrespondenceMailTask": CavcCorrespondenceMailTask.name,
      "ClearAndUnmistakeableErrorMailTask": ClearAndUnmistakeableErrorMailTask.name,
      "CongressionalInterestMailTask": CongressionalInterestMailTask.name,
      "ControlledCorrespondenceMailTask": ControlledCorrespondenceMailTask.name,
      "DeathCertificateMailTask": DeathCertificateMailTask.name,
      "DocketSwitchMailTask": DocketSwitchMailTask.name,
      "EvidenceOrArgumentMailTask": EvidenceOrArgumentMailTask.name,
      "ExtensionRequestMailTask": ExtensionRequestMailTask.name,
      "FoiaRequestMailTask": FoiaRequestMailTask.name,
      "HearingPostponementRequestMailTask": HearingPostponementRequestMailTask.name,
      "HearingRelatedMailTask": HearingRelatedMailTask.name,
      "HearingWithdrawalRequestMailTask": HearingWithdrawalRequestMailTask.name,
      "OtherMotionMailTask": OtherMotionMailTask.name,
      "PowerOfAttorneyRelatedMailTask": PowerOfAttorneyRelatedMailTask.name,
      "PrivacyActRequestMailTask": PrivacyActRequestMailTask.name,
      "PrivacyComplaintMailTask": PrivacyComplaintMailTask.name,
      "ReconsiderationMotionMailTask": ReconsiderationMotionMailTask.name,
      "ReturnedUndeliverableCorrespondenceMailTask": ReturnedUndeliverableCorrespondenceMailTask.name,
      "StatusInquiryMailTask": StatusInquiryMailTask.name
    }.with_indifferent_access

    task_types[task_type]&.constantize
  end
  # rubocop:enable Metrics/MethodLength

  def class_for_assigned_to(assigned_to)
    available_assignees = {
      "AodTeam": AodTeam.name,
      "BvaDispatch": BvaDispatch.name,
      "CaseReview": CaseReview.name,
      "CavcLitigationSupport": CavcLitigationSupport.name,
      "ClerkOfTheBoard": ClerkOfTheBoard.name,
      "Colocated": Colocated.name,
      "HearingAdmin": HearingAdmin.name,
      "LitigationSupport": LitigationSupport.name,
      "PrivacyTeam": PrivacyTeam.name
    }.with_indifferent_access

    available_assignees[assigned_to]&.constantize
  end
end
