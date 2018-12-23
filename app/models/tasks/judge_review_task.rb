class JudgeReviewTask < JudgeTask
  def baseline_actions
    [Constants.TASK_ACTIONS.JUDGE_CHECKOUT.to_h]
  end

  def label
    COPY::JUDGE_REVIEW_TASK_LABEL
  end
end
