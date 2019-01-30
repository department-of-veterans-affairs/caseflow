class JudgeDecisionReviewTask < JudgeTask
  def additional_available_actions(_user)
    [ama? ? Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.to_h : Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.to_h, Constants.TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.to_h]
  end

  def label
    COPY::JUDGE_DECISION_REVIEW_TASK_LABEL
  end
end
