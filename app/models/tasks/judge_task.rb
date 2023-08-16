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
    if (appeal.is_a?(LegacyAppeal) && assigned_to == user && FeatureToggle.enabled?(:vlj_legacy_appeal)) ||
       (assigned_to == user && appeal.is_a?(Appeal))
      [
        Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.REASSIGN_TO_JUDGE.to_h,
        additional_available_actions(user)
      ].flatten
    elsif (user&.can_act_on_behalf_of_judges? &&
        assigned_to.judge_in_vacols? && FeatureToggle.enabled?(:vlj_legacy_appeal)) ||
          (user&.can_act_on_behalf_of_judges? && appeal.is_a?(Appeal))
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

  def reassign_clears_overtime?
    FeatureToggle.enabled?(:overtime_persistence, user: RequestStore[:current_user]) ? false : true
  end
end
