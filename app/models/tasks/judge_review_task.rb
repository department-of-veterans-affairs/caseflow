class JudgeReviewTask < JudgeTask
  def baseline_actions
    [
      {
        label: COPY::JUDGE_CHECKOUT_DISPATCH_LABEL,
        value: "dispatch_decision/special_issues"
      }
    ]
  end

  def label
    COPY::JUDGE_REVIEW_TASK_LABEL
  end
end
