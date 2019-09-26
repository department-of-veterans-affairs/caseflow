# frozen_string_literal: true

##
# Task assigned to VSOs to submit an Informal Hearing Presentation for Veterans who have elected not to have a hearing.
# IHPs are a chance for VSOs to make final arguments before a case is sent to the Board.
# BVA typically (but not always) waits for an IHP to be submitted before making a decision.

class InformalHearingPresentationTask < Task
  # https://github.com/department-of-veterans-affairs/caseflow/issues/10824
  # Figure out how long IHP tasks will take to expire,
  # then make them timeable
  # include TimeableTask

  USER_ACTIONS = [
    Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
    Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
    Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
    Constants.TASK_ACTIONS.CANCEL_TASK.to_h
  ].freeze

  ADMIN_ACTIONS = [
    Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h
  ].freeze

  ORG_ACTIONS = [
    Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
    Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
    Constants.TASK_ACTIONS.CANCEL_TASK.to_h
  ].freeze

  def available_actions(user)
    if assigned_to == user
      return USER_ACTIONS
    end

    if task_is_assigned_to_user_within_organization?(user) && parent.assigned_to.user_is_admin?(user)
      return ADMIN_ACTIONS
    end

    if task_is_assigned_to_users_organization?(user)
      return ORG_ACTIONS
    end

    []
  end

  def self.label
    COPY::IHP_TASK_LABEL
  end
end
