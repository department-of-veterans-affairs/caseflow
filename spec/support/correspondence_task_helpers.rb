# frozen_string_literal: true

module CorrespondenceTaskHelpers
  def create_correspondence_intake(correspondence, user)
    parent = correspondence&.root_task
    CorrespondenceIntakeTask.create_from_params(parent, user)
  end

  def assign_review_package_task(correspondence, user)
    review_package_task = ReviewPackageTask.find_by(appeal_id: correspondence.id)
    review_package_task.update!(assigned_to: user, status: Constants.TASK_STATUSES.assigned)
  end

  def create_efolderupload_failed_task(correspondence, parent)
    correspondence.update!(
      va_date_of_receipt: rand(1.month.ago..1.day.ago),
      notes: "ABCDEFG".split("").shuffle.join
    )

    parent.update!(status: Constants.TASK_STATUSES.on_hold)
    EfolderUploadFailedTask.create!(
      parent_id: parent.id,
      appeal_id: correspondence.id,
      appeal_type: Correspondence.name,
      assigned_to: parent.assigned_to,
      status: Constants.TASK_STATUSES.in_progress
    ).update!(assigned_at: rand(1.month.ago..1.day.ago))
  end

  def process_correspondence(correspondence, user)
    rpt = ReviewPackageTask.find_by(appeal_id: correspondence.id)
    rpt.update!(status: Constants.TASK_STATUSES.completed, completed_by_id: user.id)

    cit = CorrespondenceIntakeTask.create_from_params(correspondence&.root_task, user)
    cit.update!(status: Constants.TASK_STATUSES.completed, completed_by_id: user.id)
  end

  def create_correspondence_review
    @review_correspondence = create(:correspondence)
    rpt = ReviewPackageTask.find_by(appeal_id: @review_correspondence.id)
    rpt.update!(assigned_to: current_user, status: "assigned")
    rpt.save!
  end

  def update_correspondence_for_review
    veteran = create(:veteran, first_name: "Zzzane", last_name: "Zzzans")
    review_correspondence = create(:correspondence, veteran_id: veteran.id)
    rpt = ReviewPackageTask.find_by(appeal_id: review_correspondence.id)
    rpt.update!(assigned_to: current_user,
                status: "assigned",
                assigned_at: 42.days.ago)
    rpt.save!
  end

  def correspondence_root_task_completion
    correspondence = create(:correspondence)
    correspondence.root_task.update!(status: Constants.TASK_STATUSES.completed,
                                     closed_at: rand(6 * 24 * 60).minutes.ago)
  end

  def correspondence_spec_user_access
    InboundOpsTeam.singleton.add_user(current_user)
    User.authenticate!(user: current_user)
  end

  def correspondence_spec_super_access
    InboundOpsTeam.singleton.add_user(current_super)
    User.authenticate!(user: current_super)
  end

  def correspondence_spec_privacy_user_access
    PrivacyTeam.singleton.add_user(privacy_user)
    User.authenticate!(user: privacy_user)
  end

  def correspondence_spec_cavc_user_access
    CavcLitigationSupport.singleton.add_user(cavc_user)
    User.authenticate!(user: cavc_user)
  end

  def correspondence_spec_litigation_user_access
    LitigationSupport.singleton.add_user(liti_user)
    User.authenticate!(user: liti_user)
  end

  def correspondence_spec_colocated_user_access
    Colocated.singleton.add_user(colocated_user)
    User.authenticate!(user: colocated_user)
  end

  def correspondence_spec_hearnings_user_access
    HearingAdmin.singleton.add_user(hearings_user)
    User.authenticate!(user: hearings_user)
  end

  def organizations_array_list
    @organizations_array_list ||= [
      "Education",
      "Veterans Readiness and Employment",
      "Loan Guaranty",
      "Veterans Health Administration",
      "Pension & Survivor's Benefits",
      "Fiduciary",
      "Compensation",
      "Insurance",
      "National Cemetery Administration",
      "Board Dispatch",
      "Case Review",
      "Case Movement Team",
      "BVA Intake",
      "VLJ Support Staff",
      "Transcription",
      "Translation",
      "Quality Review",
      "AOD",
      "Mail",
      "Privacy Team",
      "Litigation Support",
      "Office of Assessment and Improvement",
      "Office of Chief Counsel",
      "CAVC Litigation Support",
      "Pulac-Cerullo",
      "Hearings Management",
      "Hearing Admin",
      "Executive Management Office",
      "VLJ Support Staf"
    ]
  end
end
