class InformalHearingPresentationTask < GenericTask
  # TODO: figure out how long IHP tasks will take to expire,
  # then make them timeable
  # include Timeablity
  # TIMER_DELAY = 45.days

  def available_actions(user)
    if assigned_to == user
      return [
        Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h
      ]
    end

    if assigned_to.is_a?(Organization) && assigned_to.user_has_access?(user)
      return [
        Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h
      ]
    end

    []
  end
end
