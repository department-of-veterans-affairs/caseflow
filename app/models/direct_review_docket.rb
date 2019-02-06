class DirectReviewDocket < Docket
  DAYS_TO_DECISION_GOAL = 365

  def docket_type
    "direct_review"
  end
end
