# frozen_string_literal: true

##
# Task assigned to VSOs to submit an Informal Hearing Presentation for Veterans who have elected not to have a hearing.
# IHPs are a chance for VSOs to make final arguments before a case is sent to the Board.
# BVA typically (but not always) waits for an IHP to be submitted before making a decision.

class InformalHearingPresentationTask < GenericTask
  include TimeableTask

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

  def when_timer_ends
    if open?
      update!(
        status: Constants.TASK_STATUSES.cancelled,
        instructions: instructions << COPY.IHP_TASK_REACHED_DEADLINE_MESSAGE
      )
    end
  end

  def timer_ends_at
    created_at + deadline_length.days
  end

  private

  def deadline_length
    appeal.advanced_on_docket ? 30 : 120
  end
end
