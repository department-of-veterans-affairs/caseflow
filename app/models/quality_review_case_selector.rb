# frozen_string_literal: true

class QualityReviewCaseSelector
  # AMA Limit and Probability. See Legacy numbers at app/models/judge_case_review.rb:28
  # As of Dec 2019, we want AMA and Legacy to use the same cap. The percentages may differ. The
  # goal is to get to the cap as steadily across the month as possible
  MONTHLY_LIMIT_OF_QUAILITY_REVIEWS = 137
  QUALITY_REVIEW_SELECTION_PROBABILITY = 0.032

  class << self
    def select_case_for_quality_review?
      return false if reached_monthly_limit_in_quality_reviews?

      rand < QUALITY_REVIEW_SELECTION_PROBABILITY
    end

    def reached_monthly_limit_in_quality_reviews?
      QualityReviewTask.created_this_month.size >= MONTHLY_LIMIT_OF_QUAILITY_REVIEWS
    end
  end
end
