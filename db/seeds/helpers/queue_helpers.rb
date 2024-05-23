# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module QueueHelpers
  def create_veteran(options = {})
    @file_number += 1
    @participant_id += 1
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

  # create correspondence for given veteran/user, or create one
  def create_correspondence(user = {}, veteran = {})
    vet = veteran.blank? ? create_veteran : veteran
    user = user.blank? ? User.find_by_css_id("CAVC_LIT_SUPPORT_USER6") : user
    corr_type = CorrespondenceType.all.sample
    receipt_date = rand(1.month.ago..1.day.ago)

    ::Correspondence.create!(
      uuid: SecureRandom.uuid,
      correspondence_type_id: corr_type&.id,
      va_date_of_receipt: receipt_date,
      notes: generate_notes([package_doc_type, corr_type, receipt_date, user]),
      assigned_by_id: user.id,
      updated_by_id: user.id,
      veteran_id: vet.id,
      nod: [true, false].sample,
    ).tap
  end

  # randomly generates notes for the correspondence
  def generate_notes(params)
    note_type = params.sample

    note = ""
    # generate note from value pulled
    case note_type

    when CorrespondenceType
      note = "Correspondence Type is #{note_type&.name}"
    when ActiveSupport::TimeWithZone
      note = "Correspondence added to Caseflow on #{note_type&.strftime("%m/%d/%y")}"

    when User
      note = "This correspondence was originally assigned to and updated by #{note_type&.css_id}."
    end

    note
  end

  # :reek:UtilityFunction
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

  # :reek:UtilityFunction
  def create_correspondence_intake(correspondence, user)
    parent = correspondence&.root_task
    complete_task(ReviewPackageTask.find_by(appeal_id: correspondence.id), user.id)
    cit = CorrespondenceIntakeTask.create_from_params(parent, user)
    randomize_days_waiting_value(cit)
    cit
  end

  # :reek:UtilityFunction
  def assign_review_package_task(correspondence, user)
    review_package_task = ReviewPackageTask.find_by(appeal_id: correspondence.id)
    review_package_task.update!(
      assigned_to: user,
      status: Constants.TASK_STATUSES.assigned,
      assigned_at: rand(1.month.ago..1.day.ago)
    )
  end

  # :reek:UtilityFunction
  # :reek:FeatureEnvy
  def create_efolderupload_failed_task(correspondence, parent)
    euft = EfolderUploadFailedTask.create!(
      parent_id: parent.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_to: parent.assigned_to,
      status: Constants.TASK_STATUSES.in_progress
    )
    randomize_days_waiting_value(euft)
  end

  # :reek:UtilityFunction
  # :reek:LongParameterList
  def create_action_required_tasks(correspondence, status:, parent_task:, task_type:)
    task_type.create!(
      parent_id: parent_task.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      status: status,
      assigned_to: InboundOpsTeam.singleton
    )
  end

  # :reek:FeatureEnvy
  def create_and_complete_mail_task(correspondence, user)
    process_correspondence(correspondence, user)
    assigned_by = CorrespondenceIntakeTask.find_by(appeal_id: correspondence.id).completed_by
    cavct = CavcCorrespondenceCorrespondenceTask.find_or_create_by!(
      parent_id: correspondence&.root_task&.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_by: assigned_by,
      assigned_to: InboundOpsTeam.singleton
    )
    cavct.update!(status: Constants.TASK_STATUSES.completed)
    cavct
  end

  # :reek:FeatureEnvy
  def create_cavc_mailtask(correspondence, user)
    process_correspondence(correspondence, user)
    assigned_by = CorrespondenceIntakeTask.find_by(appeal_id: correspondence.id).completed_by
    task = CavcCorrespondenceCorrespondenceTask.create!(
      parent_id: correspondence&.root_task&.id,
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_by: assigned_by,
      assigned_to: CavcLitigationSupport.singleton,
      status: Constants.TASK_STATUSES.assigned
    )
    randomize_days_waiting_value(task)
    task
  end
  # :reek:FeatureEnvy
  def create_congress_interest_mailtask(correspondence, user)
    process_correspondence(correspondence, user)
    assigned_by = CorrespondenceIntakeTask.find_by(appeal_id: correspondence.id).completed_by
    task = CongressionalInterestCorrespondenceTask.create!(
      appeal_id: correspondence.id,
      appeal_type: "Correspondence",
      assigned_by: assigned_by,
      assigned_to: LitigationSupport.singleton,
      status: Constants.TASK_STATUSES.assigned,
      parent_id: correspondence&.root_task&.id
    )
    randomize_days_waiting_value(task)
    task
  end

  # :reek:UtilityFunction
  def complete_task(task, user_id)
    task.update!(status: Constants.TASK_STATUSES.completed, completed_by_id: user_id)
  end

  # :reek:UtilityFunction
  def process_correspondence(correspondence, user)
    rpt = ReviewPackageTask.find_by(appeal_id: correspondence.id)
    rpt.update!(status: Constants.TASK_STATUSES.completed, completed_by_id: user.id)

    cit = CorrespondenceIntakeTask.create_from_params(correspondence&.root_task, user)
    cit.update!(status: Constants.TASK_STATUSES.completed, completed_by_id: user.id)
  end

  def randomize_days_waiting_value(task)
    task.update(assigned_at: rand(1.month.ago..1.day.ago))
  end
end
