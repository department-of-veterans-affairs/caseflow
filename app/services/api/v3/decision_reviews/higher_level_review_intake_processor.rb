# frozen_string_literal: true

class Api::V3::DecisionReviews::HigherLevelReviewIntakeProcessor < Api::V3::DecisionReviews::IntakeProcessor
  def initialize(params, user)
    super(
      params: params,
      user: user,
      form_type: "higher_level_review",
      params_class: Api::V3::DecisionReviews::HigherLevelReviewIntakeParams
    )
  end

  def higher_level_review
    intake&.detail
  end
end
