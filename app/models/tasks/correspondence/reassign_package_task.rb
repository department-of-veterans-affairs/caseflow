# frozen_string_literal: true

class ReassignPackageTask < CorrespondenceTask
  before_create :verify_no_other_open_package_action_task_on_correspondence

  # :reek:UtilityFunction
  def task_url
    Constants.CORRESPONDENCE_TASK_URL.REASSIGN_PACKAGE_TASK_MODAL_URL
  end

  def approve(current_user, new_assignee)
    update!(
      completed_by: current_user,
      assigned_to_id: current_user,
      assigned_to: current_user,
      closed_at: Time.zone.now,
      status: Constants.TASK_STATUSES.completed
    )
    parent.update!(
      status: Constants.TASK_STATUSES.completed,
      closed_at: Time.zone.now,
      completed_by: current_user
    )
    ReviewPackageTask.create!(
      assigned_to: new_assignee,
      status: Constants.TASK_STATUSES.assigned,
      appeal_id: appeal_id,
      appeal_type: Correspondence.name
    )
  end

  def reject(current_user, reason)
    update!(
      completed_by_id: current_user.id,
      closed_at: Time.zone.now,
      status: Constants.TASK_STATUSES.completed,
      instructions: instructions.push(reason)
    )
    parent.update!(
      assigned_to_type: "User",
      assigned_to: assigned_by,
      status: Constants.TASK_STATUSES.in_progress
    )
  end
end
