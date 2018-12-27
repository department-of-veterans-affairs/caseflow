class JudgeReviewTask < JudgeTask
  def available_actions(_user)
    [Constants.TASK_ACTIONS.JUDGE_CHECKOUT.to_h]
  end

  def label
    COPY::JUDGE_REVIEW_TASK_LABEL
  end
end
