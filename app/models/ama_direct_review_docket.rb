class AmaDirectReviewDocket < Docket
  TIME_GOAL = 365
  BECOMES_DUE = -60

  def docket_type
    "direct_review"
  end

  # CMGTODO
  def due_count; end

  # CMGTODO
  def time_until_due_of_oldest_appeal; end

  def time_until_due_of_new_appeal
    TIME_GOAL + BECOMES_DUE
  end
end
