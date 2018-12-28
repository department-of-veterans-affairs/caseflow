class JudgeQualityReviewTask < JudgeTask
  def available_actions(_user)
    [Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h, Constants.TASK_ACTIONS.MARK_COMPLETE.to_h]
  end

  def self.verify_user_can_create!(user)
    QualityReview.singleton.user_has_access?(user) || super(user)
  end

  def label
    COPY::JUDGE_QUALITY_REVIEW_TASK_LABEL
  end
end
