# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewIntakeProcessor < Api::V3::DecisionReview::IntakeProcessor
  def initialize(params, user)
    super(params, user, "higher_level_review")
  end

  def higher_level_review
    intake.detail&.reload
  end
end
