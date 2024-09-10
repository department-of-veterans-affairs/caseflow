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

  def organizations_array_list
    @organizations_array_list ||= Constants::ORGANIZATION_NAMES.values
  end
end
