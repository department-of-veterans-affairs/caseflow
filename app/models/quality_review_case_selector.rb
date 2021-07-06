# frozen_string_literal: true

class QualityReviewCaseSelector
  # AMA Limit and Probability. See Legacy numbers at app/models/judge_case_review.rb:28
  # This probability was selected by Josh Freeman, QR Director at BVA
  MONTHLY_LIMIT_OF_QUALITY_REVIEWS = 133
  QUALITY_REVIEW_SELECTION_PROBABILITY = 0.188

  class << self
    def select_case_for_quality_review?
      return false if reached_monthly_limit_in_quality_reviews?

      rand < QUALITY_REVIEW_SELECTION_PROBABILITY
    end

    def reached_monthly_limit_in_quality_reviews?
      QualityReviewTask
        .created_this_month
        .where(assigned_to_type: Organization.name)
        .size >= MONTHLY_LIMIT_OF_QUALITY_REVIEWS
    end
  end
end
