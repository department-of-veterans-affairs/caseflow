# frozen_string_literal: true

module QueueHelpers
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

  def create_correspondence_intake(correspondence, status:)
    cit = CorrespondenceIntakeTask.create!(
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_to: MailTeamSupervisor.singleton
    )

    cit.update!(status: status)
    cit
  end

  def create_review_package_task(correspondence, status:)
    review_package_task = ReviewPackageTask.find_or_create_by!(
      appeal_id: correspondence.id,
      assigned_to: MailTeamSupervisor.singleton,
      appeal_type: "Correspondence",
    )

    review_package_task.update(status: status)
    review_package_task
  end

  def create_efolderupload_failed_task(correspondence, ptask:)
    euft = EfolderUploadFailedTask.create!(
      parent_id: ptask.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_to: MailTeamSupervisor.singleton
    )

    euft.update!(status: Constants.TASK_STATUSES.in_progress)

    euft
  end

  def create_correspondence_root_task(correspondence, status:)
    root_task = CorrespondenceRootTask.find_or_create_by!(
      appeal_id: correspondence.id,
      assigned_to: MailTeamSupervisor.singleton,
      appeal_type: "Correspondence",
    )

    root_task.update(status: status)
    root_task
  end

  def create_action_required_tasks(correspondence, status:, parent_task:, task_type:)
    task_type.create!(
      parent_id: parent_task.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: status,
      assigned_to: MailTeamSupervisor.singleton
    )
  end

  def create_in_progress_root_task_and_completed_mail_task(correspondence, status:, parent_task:)
    cavct = CavcCorrespondenceMailTask.find_or_create_by!(
      parent_id: parent_task.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_to: MailTeamSupervisor.singleton
    )
    cavct.update!(status: status)


    review_package_task = ReviewPackageTask.find_or_create_by!(
      parent_id: parent_task.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_to: MailTeamSupervisor.singleton
    )

    review_package_task.update!(status: status)

    cit = CorrespondenceIntakeTask.find_or_create_by!(
      parent_id: parent_task.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_to: MailTeamSupervisor.singleton
    )
    cit.update!(status: status)
  end

  def pending_tab_cavc_mailtask(correspondence, status:)
    cavct = CavcCorrespondenceMailTask.find_or_create_by!(
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_to: CavcLitigationSupport.singleton
    )
    cavct.update!(status: status)
  end

  def pending_tab_congress_interest_mailtask(correspondence, status:)
   cmt = CongressionalInterestMailTask.create!(
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_to: LitigationSupport.singleton
    )
    cmt.update!(status: status)
  end

  def create_pending_tasks_for_tasks_not_related_to_appeal(correspondence, parent_task:)
    # Creating Completed ReviewPackageTask
    review_package_task = ReviewPackageTask.find_or_create_by(
      parent_id: parent_task,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_to: MailTeamSupervisor.singleton
    )

    review_package_task.update(status: Constants.TASK_STATUSES.completed)

    # Creating Completed CorrespondenceIntakeTask
    correspondence_intake_task = CorrespondenceIntakeTask.find_or_create_by!(
      parent_id: parent_task,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_to: MailTeamSupervisor.singleton
    )
    correspondence_intake_task.update!(status: Constants.TASK_STATUSES.completed)
  end
end
