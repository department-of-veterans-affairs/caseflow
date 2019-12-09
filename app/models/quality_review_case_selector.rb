# frozen_string_literal: true

class QualityReviewCaseSelector
  # AMA Limit and Probability. See Legacy numbers at app/models/judge_case_review.rb:28
  # As of Dec 2019, we want AMA and Legacy to use the same numbers
  MONTHLY_LIMIT_OF_QUAILITY_REVIEWS = 137
  QUALITY_REVIEW_SELECTION_PROBABILITY = 0.032

  class << self
    def select_case_for_quality_review?
      reached_monthly_limit_in_quality_reviews? ? false : rand < QUALITY_REVIEW_SELECTION_PROBABILITY
    end
  end

  private

  def reached_monthly_limit_in_quality_reviews?
    QualityReviewTask.this_month.size >= MONTHLY_LIMIT_OF_QUAILITY_REVIEWS
  end
end
