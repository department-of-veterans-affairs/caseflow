# frozen_string_literal: true

module SeedHelpers
  def create_veteran(options = {})
    @file_number += 1
    @participant_id += 1
    params = {
      file_number: format("%<n>09d", n: @file_number),
      participant_id: format("%<n>09d", n: @participant_id)
    }
    create(:veteran, params.merge(options))
  end

  def create_appeal(veteran)
    ::Appeal.create!(
      veteran_file_number: veteran.file_number,
      docket_type: Constants.AMA_DOCKETS.direct_review
    )
  end
  def create_correspondence(appeal)
    correspondence = ::Correspondence.create!(
      uuid: SecureRandom.uuid,
      portal_entry_date: Time.zone.now,
      source_type: "Mail",
      package_document_type_id: (1..20).to_a.sample,
      correspondence_type_id: 4,
      cmp_queue_id: 1,
      cmp_packet_number: @cmp_packet_number,
      va_date_of_receipt: Time.zone.yesterday,
      notes: "Notes from CMP - Multi Correspondence Seed",
      assigned_by_id: 81,
      updated_by_id: 81,
      veteran_id: appeal.veteran.id
    ).tap { @cmp_packet_number += 1 }

    correspondence.appeals << appeal

    create_correspondence_document(correspondence, appeal.veteran)
    correspondence
  end

  def create_correspondence_document(correspondence, veteran)
    CorrespondenceDocument.create!(
      document_file_number: veteran.file_number,
      uuid: SecureRandom.uuid,
      vbms_document_type_id: 1250,
      document_type: 1250,
      pages: 30,
      correspondence_id: correspondence.id
    )
  end

  def create_correspondence_intake(correspondence)
    CorrespondenceIntakeTask.create!(
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: Constants.TASK_STATUSES.in_progress,
      assigned_to: MailTeamSupervisor.singleton
    )
  end

  def create_review_package_task(correspondence, status:)
    ReviewPackageTask.create!(
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: status,
      assigned_to: MailTeamSupervisor.singleton
    )
  end

  def create_efolderupload_failed_task(correspondence, ptask:)
    EfolderUploadFailedTask.create!(
      parent_id: ptask.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: Constants.TASK_STATUSES.in_progress,
      assigned_to: MailTeamSupervisor.singleton
    )
  end

  def create_correspondence_root_task(correspondence, status:)
    CorrespondenceRootTask.create!(
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: status,
      assigned_to: MailTeamSupervisor.singleton
    )
  end

  def create_action_required_tasks(correspondence, status:, parent_task:)
    ReassignPackageTask.create!(
      parent_id: parent_task.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: status,
      assigned_to: MailTeamSupervisor.singleton
    )
    RemovePackageTask.create!(
      parent_id: parent_task.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: status,
      assigned_to: MailTeamSupervisor.singleton
    )
    SplitPackageTask.create!(
      parent_id: parent_task.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: status,
      assigned_to: MailTeamSupervisor.singleton
    )
    MergePackageTask.create!(
      parent_id: parent_task.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: status,
      assigned_to: MailTeamSupervisor.singleton
    )
  end

  def create_in_progress_root_task_and_completed_mail_task(correspondence, status:, parent_task:)
    CavcCorrespondenceMailTask.create!(
      parent_id: parent_task.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: status,
      assigned_to: MailTeamSupervisor.singleton
    )
    ReviewPackageTask.create!(
      parent_id: parent_task.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: status,
      assigned_to: MailTeamSupervisor.singleton
    )
    CorrespondenceIntakeTask.create!(
      parent_id: parent_task.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: status,
      assigned_to: MailTeamSupervisor.singleton
    )
  end

  def pending_tab_cavc_mailtask(correspondence)
    CavcCorrespondenceMailTask.create!(
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: Constants.TASK_STATUSES.assigned,
      assigned_to: MailTeamSupervisor.singleton
    )
  end

  def pending_tab_congress_interest_mailtask(correspondence)
    CongressionalInterestMailTask.create!(
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: Constants.TASK_STATUSES.assigned,
      assigned_to: MailTeamSupervisor.singleton
    )
  end

  def create_pending_tasks_for_tasks_not_related_to_appeal(correspondence, parent_task:)
    # Creating Completed ReviewPackageTask
    review_package_task = ReviewPackageTask.create!(
      parent_id: parent_task,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: Constants.TASK_STATUSES.completed,
      assigned_to: MailTeamSupervisor.singleton
    )

    # Creating Completed CorrespondenceIntakeTask
    correspondence_intake_task = CorrespondenceIntakeTask.create!(
      parent_id: parent_task,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: Constants.TASK_STATUSES.completed,
      assigned_to: MailTeamSupervisor.singleton
    )
  end
end
