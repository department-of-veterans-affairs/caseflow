# frozen_string_literal: true

module CorrespondenceTaskHelpers
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

  def process_correspondence(correspondence, user)
    rpt = ReviewPackageTask.find_by(appeal_id: correspondence.id)
    rpt.update!(status: Constants.TASK_STATUSES.completed, completed_by_id: user.id)

    cit = CorrespondenceIntakeTask.create_from_params(correspondence&.root_task, user)
    cit.update!(status: Constants.TASK_STATUSES.completed, completed_by_id: user.id)
  end
end
