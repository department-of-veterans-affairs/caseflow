# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module QueueHelpers
  def create_veteran(options = {})
    @file_number += 1
    @participant_id += 1
    @cmp_packet_number ||= 1_000_000_000
    params = {
      file_number: format("%<n>09d", n: @file_number),
      participant_id: format("%<n>09d", n: @participant_id)
    }
    veteran = create(:veteran, params.merge(options))
    2.times do
      appeal = create(:appeal, veteran_file_number: veteran.file_number)
      InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
    end
    veteran
  end

  def create_correspondence
    vet = create_veteran
    correspondence = ::Correspondence.create!(
      uuid: SecureRandom.uuid,
      portal_entry_date: Time.zone.now,
      source_type: "Mail",
      package_document_type_id: (1..20).to_a.sample,
      correspondence_type_id: CorrespondenceType.all.sample&.id,
      cmp_queue_id: 1,
      cmp_packet_number: @cmp_packet_number,
      va_date_of_receipt: rand(1.month.ago..1.day.ago),
      notes: "Notes from CMP - Queue Correspondence Seed",
      assigned_by_id: 81,
      updated_by_id: 81,
      veteran_id: vet.id
    ).tap { @cmp_packet_number += 1 }

    # create_correspondence_document(correspondence, vet)
    correspondence
  end

  def create_correspondence_document(correspondence, veteran)
    CorrespondenceDocument.find_or_create_by!(
      document_file_number: veteran.file_number,
      uuid: SecureRandom.uuid,
      vbms_document_type_id: 1250,
      document_type: 1250,
      pages: 30,
      correspondence_id: correspondence.id
    )
  end

  def create_correspondence_intake(correspondence, user)
    parent = correspondence&.root_task
    cit = CorrespondenceIntakeTask.create_from_params(parent, user)
    cit
  end

  def assign_review_package_task(correspondence, user)
    review_package_task = ReviewPackageTask.find_by(appeal_id: correspondence.id)
    review_package_task.update!(assigned_to: user, status: Constants.TASK_STATUSES.assigned)
  end

  def create_efolderupload_failed_task(correspondence, parent)
    EfolderUploadFailedTask.create!(
      parent_id: parent.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_to: parent.assigned_to,
      status: Constants.TASK_STATUSES.in_progress
    )
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

  def create_and_complete_mail_task(correspondence, user)
    process_correspondence(correspondence, user)
    assigned_by = CorrespondenceIntakeTask.find_by(appeal_id: correspondence.id).completed_by
    cavct = CavcCorrespondenceMailTask.find_or_create_by!(
      parent_id: correspondence&.root_task&.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_by: assigned_by,
      assigned_to: MailTeamSupervisor.singleton
    )
    cavct.update!(status: Constants.TASK_STATUSES.completed)
    cavct
  end

  def create_cavc_mailtask(correspondence, user)
    process_correspondence(correspondence, user)
    assigned_by = CorrespondenceIntakeTask.find_by(appeal_id: correspondence.id).completed_by
    cavct = CavcCorrespondenceMailTask.create!(
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_by: assigned_by,
      assigned_to: CavcLitigationSupport.singleton,
      status: Constants.TASK_STATUSES.assigned
    )
    cavct
  end

  def create_congress_interest_mailtask(correspondence, user)
    process_correspondence(correspondence, user)
    assigned_by = CorrespondenceIntakeTask.find_by(appeal_id: correspondence.id).completed_by
    cmt = CongressionalInterestMailTask.create!(
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_by: assigned_by,
      assigned_to: LitigationSupport.singleton,
      status: Constants.TASK_STATUSES.assigned,
      parent_id: correspondence&.root_task&.id
    )
    cmt
  end

  def process_correspondence(correspondence, user)
    rpt = ReviewPackageTask.find_by(appeal_id: correspondence.id)
    rpt.update!(status: Constants.TASK_STATUSES.completed, completed_by_id: user.id)

    cit = CorrespondenceIntakeTask.create_from_params(correspondence&.root_task, user)
    cit.update!(status: Constants.TASK_STATUSES.completed, completed_by_id: user.id)
  end
end
# rubocop:enable Metrics/ModuleLength
