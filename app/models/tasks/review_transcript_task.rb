class ReviewTranscriptTask < Task

  before_validation :set_assignee

  USER_ACTIONS = [
    Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
    Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
    Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
    Constants.TASK_ACTIONS.CANCEL_TASK.to_h
  ].freeze

  def available_actions(user)
    return USER_ACTIONS if assigned_to == user
    []
  end

  def set_assignee
    self.assigned_to ||= HearingAdmin.singleton
  end

end
