# frozen_string_literal: true

# :reek:DataClump
# :reek:FeatureEnvy
class CorrespondenceIntakeProcessor
  def process_intake(intake_params, current_user)
    correspondence = Correspondence.find_by(uuid: intake_params[:correspondence_uuid])

    fail "Correspondence not found" if correspondence.blank?

    parent_task = CorrespondenceIntakeTask.find_by(appeal_id: correspondence.id)

    return false if !correspondence_documents_efolder_uploader.upload_documents_to_claim_evidence(
      correspondence,
      current_user,
      parent_task
    )

    do_upload_success_actions(parent_task, intake_params, correspondence, current_user)
  end

  def update_correspondence(intake_params)
    # Fetch the correspondence using the UUID from the intake params
    correspondence = Correspondence.find_by(uuid: intake_params[:correspondence_uuid])

    # Fail if correspondence is not found
    fail "Correspondence not found" if correspondence.blank?

    ActiveRecord::Base.transaction do
      # Ensure relations removal logic is in place
      remove_correspondence_relations(intake_params, correspondence)

      # Additional logic to update correspondence fields if necessary (optional)
    end

    # Return success after successful update
    true
  rescue StandardError => error
    Rails.logger.error(error.full_message)
    false
  end

  def create_letter(params, _current_user)
    correspondence = Correspondence.find_by(uuid: params[:correspondence_uuid])

    fail "Correspondence not found" if correspondence.blank?

    create_response_letter(params, correspondence.id)
  end

  private

  # :reek:LongParameterList
  def do_upload_success_actions(parent_task, intake_params, correspondence, current_user)
    ActiveRecord::Base.transaction do
      parent_task.update!(status: Constants.TASK_STATUSES.completed)

      create_correspondence_relations(intake_params, correspondence.id)
      create_response_letter(intake_params, correspondence.id)
      add_tasks_to_related_appeals(intake_params, current_user, correspondence.id)
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

  def remove_correspondence_relations(intake_params, correspondence)
    # Get the UUIDs of related correspondences that are to be removed (unchecked)
    removed_related_uuids = intake_params[:correspondence_relations]&.map { |data| data[:uuid] }

    # Find and remove only those relations that were unchecked
    relations_to_remove = CorrespondenceRelation.where(
      correspondence_id: correspondence.id,
      related_correspondence_id: Correspondence.where(uuid: removed_related_uuids).pluck(:id)
    )

    relations_to_remove.each(&:destroy!)
  end

  def create_response_letter(intake_params, correspondence_id)
    current_user = RequestStore.store[:current_user] ||= User.system_user

    intake_params[:response_letters]&.map do |data|
      current_value = nil
      if data[:responseWindows] == "Custom"
        current_value = data[:customValue]
      end

      if data[:responseWindows] == "65 days"
        current_value = 65
      end

      CorrespondenceResponseLetter.create!(
        correspondence_id: correspondence_id,
        date_sent: data[:date],
        title: data[:title],
        subcategory: data[:subType],
        reason: data[:reason],
        response_window: current_value,
        letter_type: data[:type],
        user_id: current_user.id
      )
    end
  end

  def link_appeals_to_correspondence(intake_params, correspondence_id)
    intake_params[:related_appeal_ids]&.map do |appeal_id|
      CorrespondenceAppeal.find_or_create_by(correspondence_id: correspondence_id, appeal_id: appeal_id)
    end
  end

  def create_appeal_related_tasks(data, current_user, correspondence_id)
    appeal = Appeal.find(data[:appeal_id])
    # find the CorrespondenceAppeal created in link_appeals_to_correspondence
    cor_appeal = CorrespondenceAppeal.find_by(
      correspondence_id: correspondence_id,
      appeal_id: appeal.id
    )
    task = task_class_for_task_related(data).create_from_params(
      {
        appeal: appeal,
        parent_id: appeal.root_task&.id,
        assigned_to: class_for_assigned_to(data[:assigned_to]).singleton,
        instructions: data[:content]
      }, current_user
    )
    # create join table to CorrespondenceAppealTask for tracking
    CorrespondencesAppealsTask.find_or_create_by(
      correspondence_appeal: cor_appeal,
      task: task
    )
  end

  def add_tasks_to_related_appeals(intake_params, current_user, correspondence_id)
    link_appeals_to_correspondence(intake_params, correspondence_id)
    intake_params[:tasks_related_to_appeal]&.map do |data|
      create_appeal_related_tasks(data, current_user, correspondence_id)
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
      task_class_for_task_unrelated(data).create_from_params(
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

  def task_class_for_task_related(data)
    task_type = data[:klass]
    TASKS_RELATED_TO_APPEAL_TASK_TYPES[task_type]&.constantize
  end

  def task_class_for_task_unrelated(data)
    task_type = data[:klass]
    CorrespondenceTask.tasks_not_related_to_an_appeal_names
      .find { |name| name == task_type }&.constantize
  end

  def correspondence_documents_efolder_uploader
    @correspondence_documents_efolder_uploader ||= CorrespondenceDocumentsEfolderUploader.new
  end

  def mail_task_class_for_type(task_type)
    mail_task_types = {
      AssociatedWithClaimsFolderMailTask.label => AssociatedWithClaimsFolderMailTask.name,
      AddressChangeCorrespondenceMailTask.label => AddressChangeCorrespondenceMailTask.name,
      EvidenceOrArgumentCorrespondenceMailTask.label => EvidenceOrArgumentCorrespondenceMailTask.name,
      VacolsUpdatedMailTask.label => VacolsUpdatedMailTask.name
    }.with_indifferent_access

    mail_task_types[task_type]&.constantize
  end

  TASKS_RELATED_TO_APPEAL_TASK_TYPES = {
    CavcCorrespondenceMailTask.name => CavcCorrespondenceMailTask.name,
    ClearAndUnmistakeableErrorMailTask.name => ClearAndUnmistakeableErrorMailTask.name,
    AddressChangeMailTask.name => AddressChangeMailTask.name,
    CongressionalInterestMailTask.name => CongressionalInterestMailTask.name,
    ControlledCorrespondenceMailTask.name => ControlledCorrespondenceMailTask.name,
    DeathCertificateMailTask.name => DeathCertificateMailTask.name,
    DocketSwitchMailTask.name => DocketSwitchMailTask.name,
    EvidenceOrArgumentMailTask.name => EvidenceOrArgumentMailTask.name,
    ExtensionRequestMailTask.name => ExtensionRequestMailTask.name,
    FoiaRequestMailTask.name => FoiaRequestMailTask.name,
    HearingPostponementRequestMailTask.name => HearingPostponementRequestMailTask.name,
    HearingRelatedMailTask.name => HearingRelatedMailTask.name,
    HearingWithdrawalRequestMailTask.name => HearingWithdrawalRequestMailTask.name,
    ReconsiderationMotionMailTask.name => ReconsiderationMotionMailTask.name,
    AodMotionMailTask.name => AodMotionMailTask.name,
    OtherMotionMailTask.name => OtherMotionMailTask.name,
    PowerOfAttorneyRelatedMailTask.name => PowerOfAttorneyRelatedMailTask.name,
    PrivacyActRequestMailTask.name => PrivacyActRequestMailTask.name,
    PrivacyComplaintMailTask.name => PrivacyComplaintMailTask.name,
    ReturnedUndeliverableCorrespondenceMailTask.name => ReturnedUndeliverableCorrespondenceMailTask.name,
    StatusInquiryMailTask.name => StatusInquiryMailTask.name,
    AppealWithdrawalMailTask.name => AppealWithdrawalMailTask.name
  }.with_indifferent_access

  def class_for_assigned_to(assigned_to)
    available_assignees = {
      AodTeam.name => AodTeam.name,
      BvaDispatch.name => BvaDispatch.name,
      CaseReview.name => CaseReview.name,
      CavcLitigationSupport.name => CavcLitigationSupport.name,
      ClerkOfTheBoard.name => ClerkOfTheBoard.name,
      Colocated.name => Colocated.name,
      HearingAdmin.name => HearingAdmin.name,
      LitigationSupport.name => LitigationSupport.name,
      PrivacyTeam.name => PrivacyTeam.name
    }.with_indifferent_access

    available_assignees[assigned_to]&.constantize
  end
end
