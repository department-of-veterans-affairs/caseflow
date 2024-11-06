# frozen_string_literal: true

class RemovePackageTask < CorrespondenceTask
  before_create :verify_no_other_open_package_action_task_on_correspondence

  # :reek:UtilityFunction
  def task_url
    Constants.CORRESPONDENCE_TASK_URL.REMOVE_PACKAGE_TASK_MODAL_URL
  end

  def approve(user)
    update!(
      completed_by_id: user.id,
      status: Constants.TASK_STATUSES.cancelled
    )
  end

  def reject(user, reason)
    update!(
      completed_by_id: user.id,
      closed_at: Time.zone.now,
      status: Constants.TASK_STATUSES.completed,
      instructions: instructions.push(reason)
    )
    parent.update!(
      status: Constants.TASK_STATUSES.in_progress
    )
  end
end
