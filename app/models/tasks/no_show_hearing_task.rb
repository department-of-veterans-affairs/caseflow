# frozen_string_literal: true

# Task created after an appellant no-shows for a hearing. Gives the hearings team the options to decide how to handle
# the no-show hearing after the judge indicates that the appellant no-showed.
class NoShowHearingTask < Task
  before_validation :set_assignee

  def self.create_with_hold(parent_task)
    multi_transaction do
      create!(parent: parent_task, appeal: parent_task.appeal).tap do |no_show_hearing_task|
        TimedHoldTask.create_from_parent(
          no_show_hearing_task,
          days_on_hold: 25,
          instructions: ["Mail must be received within 14 days of the original hearing date."]
        )
      end
    end
  end

  def available_actions(user)
    hearing_admin_actions = available_hearing_user_actions(user)

    if (assigned_to &.== user) || task_is_assigned_to_users_organization?(user)
      [
        Constants.TASK_ACTIONS.RESCHEDULE_NO_SHOW_HEARING.to_h,
        Constants.TASK_ACTIONS.MARK_NO_SHOW_HEARING_COMPLETE.to_h,
        Constants.TASK_ACTIONS.CREATE_CHANGE_HEARING_DISPOSITION_TASK.to_h
      ] | hearing_admin_actions
    else
      hearing_admin_actions
    end
  end

  # overriding to allow action on an on_hold task
  def actions_available?(user)
    actions_allowable?(user)
  end

  def reschedule_hearing
    multi_transaction do
      update!(status: Constants.TASK_STATUSES.completed)
      # Attach the new task to the same parent as the previous HearingTask.
      ScheduleHearingTask.create!(appeal: appeal, parent: ancestor_task_of_type(HearingTask)&.parent)
    end
  end

  private

  def set_assignee
    self.assigned_to ||= HearingsManagement.singleton
  end
end
