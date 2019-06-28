# frozen_string_literal: true

##
# Parent class for all tasks to be completed by judges, including
# JudgeQualityReviewTasks, JudgeDecisionReviewTasks,
# JudgeDispatchReturnTasks, and JudgeAssignTasks.

class JudgeTask < Task
  def available_actions(user)
    [
      Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
      Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
      additional_available_actions(user)
    ].flatten
  end

  def actions_available?(user)
    assigned_to == user
  end

  def additional_available_actions(_user)
    fail Caseflow::Error::MustImplementInSubclass
  end

  def timeline_title
    COPY::CASE_TIMELINE_JUDGE_TASK
  end

  def previous_task
    children_attorney_tasks.order(:assigned_at).last
  end
end
