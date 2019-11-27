# frozen_string_literal: true

#benefit type error
class Api::V3::DecisionReview::HigherLevelReviewIntakeParams::Data < Api::V3::DecisionReview::Params
  def initialize(params)
    @hash = params
    @errors = Array.wrap(
      type_error_for_key(
        ["type", "HigherLevelReview"],
        ["attributes", OBJECT],
      ) || self.class::Attributes.new(hash["attributes"]).errors
    ).flatten
  end
end
