# frozen_string_literal: true

##
# Task assigned to VSOs to submit an Informal Hearing Presentation for Veterans who have elected not to have a hearing.
# IHPs are a chance for VSOs to make final arguments before a case is sent to the Board.
# BVA typically (but not always) waits for an IHP to be submitted before making a decision.

class InformalHearingPresentationTask < GenericTask
  # TODO: figure out how long IHP tasks will take to expire,
  # then make them timeable
  # include TimeableTask

  def available_actions(user)
    if assigned_to == user
      return [
        Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end

    if task_is_assigned_to_users_organization?(user)
      return [
        Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end

    []
  end

  def label
    COPY::IHP_TASK_LABEL
  end
end
