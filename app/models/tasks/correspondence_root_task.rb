# frozen_string_literal: true

class CorrespondenceRootTask < CorrespondenceTask
  def correspondence_status
    status = if action_required?
               Constants.CORRESPONDENCE_STATUSES.action_required
             elsif unassigned?
               Constants.CORRESPONDENCE_STATUSES.unassigned
             elsif assigned?
               Constants.CORRESPONDENCE_STATUSES.assigned
             elsif pending?
               Constants.CORRESPONDENCE_STATUSES.pending
             elsif completed?
               Constants.CORRESPONDENCE_STATUSES.completed
             else
               ""
             end
    status
  end

  def review_package_task
    children.open.find_by(type: ReviewPackageTask.name)
  end

  def open_intake_task
    children.open.find_by(type: CorrespondenceIntakeTask.name)
  end

  def open_package_action_task
    CorrespondenceTask.action_required_tasks.find_by(appeal_id: appeal_id, appeal_type: appeal_type)
  end

  def tasks_not_related_to_an_appeal
    CorrespondenceTask.tasks_not_related_to_an_appeal.open.where(appeal_id: appeal_id, appeal_type: appeal_type)
  end

  def closed_tasks_not_related_to_an_appeal
    CorrespondenceTask.tasks_not_related_to_an_appeal.closed.where(appeal_id: appeal_id, appeal_type: appeal_type)
  end

  # correspondence_mail_tasks are completed upon creation, so no open check
  def correspondence_mail_tasks
    CorrespondenceTask.correspondence_mail_tasks.where(appeal_id: appeal_id, appeal_type: appeal_type)
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
    review_package_task&.status == Constants.TASK_STATUSES.unassigned
  end

  # assigned if open (assigned or on hold status) review package task or intake task
  def assigned?
    !unassigned? && (!review_package_task.blank? || !open_intake_task.blank?)
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
    status == Constants.TASK_STATUSES.completed || children.open.blank?
  end
end
