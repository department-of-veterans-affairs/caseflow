# frozen_string_literal: true

# Task created after an appellant no-shows for a hearing. Gives the hearings team the options to decide how to handle
# the no-show hearing after the judge indicates that the appellant no-showed.
class NoShowHearingTask < GenericTask
  before_validation :set_assignee

  def available_actions(user)
    if (assigned_to && assigned_to == user) || task_is_assigned_to_users_organization?(user)
      # TODO: Should these also be assignable to people?
      [
        Constants.TASK_ACTIONS.RESCHEDULE_HEARING.to_h
      ]
    else
      []
    end
  end

  private

  def set_assignee
    self.assigned_to = HearingAdmin.singleton
  end
end
