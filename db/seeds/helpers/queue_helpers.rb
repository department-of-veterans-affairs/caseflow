# frozen_string_literal: true

require_relative 'document_manager'
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

  # create correspondence for given veteran/user
  def create_correspondence(user = {}, veteran = {})
    vet = veteran
    user = user.blank? ? InboundOpsTeam.singleton.users.first : user
    corr_type = CorrespondenceType.all.sample
    receipt_date = rand(1.month.ago..1.day.ago)
    nod = [true, false].sample
    doc_type = generate_vbms_doc_type(nod)

    correspondence = ::Correspondence.create!(
      uuid: SecureRandom.uuid,
      va_date_of_receipt: receipt_date,
      notes: generate_notes([corr_type, receipt_date, user]),
      veteran_id: vet.id,
      nod: nod
    )
    DocumentManager.create_correspondence_document(correspondence, vet, doc_type)

    return correspondence
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
    parent.update!(status: Constants.TASK_STATUSES.on_hold)
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

  def create_multiple_docs(corres, veteran)
    CorrespondenceDocument.find_or_create_by(
      document_file_number: veteran.file_number,
      uuid: SecureRandom.uuid,
      correspondence_id: corres.id,
      document_type: 1250,
      pages: 30,
      vbms_document_type_id: 1250
    )
    CorrespondenceDocument.find_or_create_by(
      document_file_number: veteran.file_number,
      uuid: SecureRandom.uuid,
      correspondence_id: corres.id,
      document_type: 719,
      pages: 20,
      vbms_document_type_id: 719
    )
    CorrespondenceDocument.find_or_create_by(
      document_file_number: veteran.file_number,
      uuid: SecureRandom.uuid,
      correspondence_id: corres.id,
      document_type: 672,
      pages: 10,
      vbms_document_type_id: 672
    )
    CorrespondenceDocument.find_or_create_by(
      document_file_number: veteran.file_number,
      uuid: SecureRandom.uuid,
      correspondence_id: corres.id,
      document_type: 18,
      pages: 5,
      vbms_document_type_id: 18
    )
  end

  def generate_vbms_doc_type(nod)
    return nod_doc if nod

    non_nod_docs.sample
  end

  def nod_doc
    {
      id: 1250,
      description: "VA Form 10182, Decision Review Request: Board Appeal (Notice of Disagreement)"
    }
  end

  # rubocop:disable Metrics/MethodLength
  def non_nod_docs
    [
      {
        id: 1419,
        description: "Reissuance Beneficiary Notification Letter"
      },
      {
        id: 1430,
        description: "Bank Letter Beneficiary"
      },
      {
        id: 1448,
        description: "VR-69 Chapter 36 Decision Letter"
      },
      {
        id: 1452,
        description: "Apportionment - notice to claimant"
      },
      {
        id: 1505,
        description: "Higher-Level Review (HLR) Not Timely Letter"
      },
      {
        id: 1578,
        description: "Pension End of Day Letter"
      }
    ]
  end
end
