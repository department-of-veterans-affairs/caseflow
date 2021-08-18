# frozen_string_literal: true

##
# Task for a judge to review decisions.
# A JudgeDecisionReviewTask implies that there is a decision that needs to be reviewed from an attorney.
# The case associated with this task appears in the judge's Cases to review view
# There should only ever be one open JudgeDecisionReviewTask at a time for an appeal.
# If an AttorneyTask is cancelled, we would want to cancel both it and its parent JudgeDecisionReviewTask
# and create a new JudgeAssignTask, because another assignment by a judge is needed.

class JudgeDecisionReviewTask < JudgeTask
  validate :only_open_task_of_type, on: :create,
                                    unless: :skip_check_for_only_open_task_of_type

  def additional_available_actions(user)
    return [] unless assigned_to == user

    judge_checkout_label = if ama?
                             ama_judge_actions(user)
                           else
                             Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.to_h
                           end

    [
      (Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h if ama? && appeal.vacate?),
      judge_checkout_label,
      Constants.TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.to_h
    ].compact
  end

  def self.label
    COPY::JUDGE_DECISION_REVIEW_TASK_LABEL
  end

  private

  def ama_judge_actions(user)
    if FeatureToggle.enabled?(:special_issues_revamp, user: user)
      return Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT_SP_ISSUES.to_h
    end

    Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.to_h
  end
end
