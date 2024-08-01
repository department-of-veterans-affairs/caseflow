# frozen_string_literal: true

class CorrespondenceRootTask < CorrespondenceTask
  def correspondence_status
    return Constants.CORRESPONDENCE_STATUSES.unassigned if unassigned?
    return Constants.CORRESPONDENCE_STATUSES.assigned if assigned?
    return Constants.CORRESPONDENCE_STATUSES.action_required if action_required?
    return Constants.CORRESPONDENCE_STATUSES.pending if pending?
    return Constants.CORRESPONDENCE_STATUSES.completed if completed?
  end

  def open_review_package_task
    children.open.find_by(type: ReviewPackageTask.name)
  end

  def open_intake_task
    children.open.find_by(type: CorrespondenceIntakeTask.name)
  end

  def open_package_action_task
    CorrespondenceTask.package_action_tasks.open.find_by(
      appeal_id: appeal_id,
      appeal_type: appeal_type,
      status: Constants.TASK_STATUSES.assigned
    )
  end

  def tasks_not_related_to_an_appeal
    CorrespondenceMailTask.open.where(appeal_id: appeal_id, appeal_type: appeal_type)
  end

  # a correspondence root task is considered closed if it has a closed at
  # date OR all children tasks are completed.
  def completed_by_date
    return closed_at unless closed_at.nil?

    if children&.all?(&:completed?)
      children.maximum(:closed_at)
    end
  end

  private

  # logic for handling correspondence statuses
  # unassigned if review package task is unassigned
  def unassigned?
    open_review_package_task&.status == Constants.TASK_STATUSES.unassigned
  end

  # assigned if open (assigned or on hold status) review package task or intake task
  def assigned?
    !unassigned? && (!open_review_package_task.blank? || !open_intake_task.blank?)
  end

  # action required if the correspondence has a package action task with a status of 'assigned'
  def action_required?
    !open_package_action_task.blank?
  end

  def pending?
    !tasks_not_related_to_an_appeal.blank?
  end

  # completed if root task is closed or no open children tasks
  def completed?
    completed? || children.open.blank?
  end
end
