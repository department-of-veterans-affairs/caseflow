# frozen_string_literal: true

class HigherLevelReviewsController < ClaimReviewController
  SOURCE_TYPE = "HigherLevelReview"

  private

  def source_type
    SOURCE_TYPE
  end

  alias higher_level_review claim_review
  helper_method :higher_level_review
end
