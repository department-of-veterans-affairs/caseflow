# frozen_string_literal: true

class Api::V3::DecisionReview::HigherLevelReviewIntakeParams::Included < Api::V3::DecisionReview::Params
  def initialize(params)
    return "#{self.hash_path_str} should be an array" unless params.is_array? 

    @errors = params.map do |included_item|
      self.class::ContestableIssue.new(included_item).errors
    end.flatten
  end
end
