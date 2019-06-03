# frozen_string_literal: true

##
# Task automatically assigned to the Hearing Admin organization and/or a member of that team
# when a disposition has not been set on a hearing that was held more than 48 hours ago.
class ChangeHearingDispositionTask < DispositionTask
  before_validation :set_assignee

  def available_actions(_user)
    [
      appropriate_timed_hold_task_action,
      Constants.TASK_ACTIONS.CHANGE_HEARING_DISPOSITION.to_h,
      Constants.TASK_ACTIONS.ASSIGN_TO_HEARING_ADMIN_MEMBER.to_h
    ]
  end

  def actions_allowable?(user)
    HearingAdmin.singleton.user_has_access?(user) && super
  end

  private

  def set_assignee
    self.assigned_to ||= HearingAdmin.singleton
  end
end
