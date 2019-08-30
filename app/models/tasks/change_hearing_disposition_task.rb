# frozen_string_literal: true

##
# Task automatically assigned to the Hearing Admin organization and/or a member of that team
# when a disposition has not been set on a hearing that was held more than 48 hours ago.
class ChangeHearingDispositionTask < AssignHearingDispositionTask
  before_validation :set_assignee

  def self.label
    "Change hearing disposition"
  end

  def default_instructions
    [COPY::CHANGE_HEARING_DISPOSITION_TASK_DEFAULT_INSTRUCTIONS]
  end

  def available_actions(_user)
    [
      Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
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
