class JudgeDecisionReviewTask < JudgeTask
  def additional_available_actions(_user)
    [Constants.TASK_ACTIONS.JUDGE_CHECKOUT.to_h]
  end

  def label
    COPY::JUDGE_DECISION_REVIEW_TASK_LABEL
  end
end
