# frozen_string_literal: true

##
# Parent class for all tasks to be completed by judges, including
# - JudgeQualityReviewTasks
# - JudgeDecisionReviewTasks
# - JudgeDispatchReturnTasks
# - JudgeAssignTasks
# - JudgeAddressMotionToVacateTasks

class JudgeTask < Task
  def available_actions(user)
    # Only the current assignee of a judge task should have actions available to them on the judge task.
    if assigned_to == user
      [
        Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h,
        additional_available_actions(user)
      ].flatten
    elsif user.can_act_on_behalf_of_judges?
      [
        Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h,
        additional_available_actions(user)
      ].flatten
    else
      []
    end
  end

  # :nocov:
  def additional_available_actions(_user)
    fail Caseflow::Error::MustImplementInSubclass
  end
  # :nocov:

  def timeline_title
    COPY::CASE_TIMELINE_JUDGE_TASK
  end

  def previous_task
    children_attorney_tasks.order(:assigned_at).last
  end
end
