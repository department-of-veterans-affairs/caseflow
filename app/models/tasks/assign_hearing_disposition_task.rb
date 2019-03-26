# frozen_string_literal: true

##
# Task automatically assigned to the Hearing Admin organization and/or a member of that team
# when a disposition has not been set on a hearing that was held more than 48 hours ago.
class AssignHearingDispositionTask < DispositionTask
  before_validation :set_assignee

  def available_actions(_user)
    [Constants.TASK_ACTIONS.POSTPONE_HEARING.to_h, Constants.TASK_ACTIONS.ASSIGN_HEARING_DISPOSITION.to_h]
  end

  private

  def set_assignee
    self.assigned_to ||= HearingAdmin.singleton
  end
end
