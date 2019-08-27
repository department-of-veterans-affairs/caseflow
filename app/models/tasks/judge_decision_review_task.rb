# frozen_string_literal: true

##
# Task for a judge to review decisions.

class JudgeDecisionReviewTask < JudgeTask
  def additional_available_actions(_user)
    judge_checkout_label = if ama?
                             Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.to_h
                           else
                             Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.to_h
                           end
    [judge_checkout_label, Constants.TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.to_h]
  end

  def self.label
    COPY::JUDGE_DECISION_REVIEW_TASK_LABEL
  end
end
