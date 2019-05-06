# frozen_string_literal: true

# Task created after an appellant no-shows for a hearing. Gives the hearings team the options to decide how to handle
# the no-show hearing after the judge indicates that the appellant no-showed.
class NoShowHearingTask < GenericTask
  before_validation :set_assignee

  def available_actions(user)
    if (assigned_to &.== user) || task_is_assigned_to_users_organization?(user)
      [
        Constants.TASK_ACTIONS.RESCHEDULE_NO_SHOW_HEARING.to_h,
        Constants.TASK_ACTIONS.MARK_NO_SHOW_HEARING_COMPLETE.to_h
      ]
    else
      []
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

  def complete_data(_user = nil)
    {
      modal_body: COPY::NO_SHOW_HEARING_TASK_COMPLETE_MODAL_BODY
    }
  end

  private

  def set_assignee
    self.assigned_to ||= HearingsManagement.singleton
  end
end
