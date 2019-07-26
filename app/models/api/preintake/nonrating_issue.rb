# frozen_string_literal: true

class Api::Preintake::NonratingIssue < Api::Preintake::RequestIssue
  include Api::Validation

  attr_reader :nonrating_issue_category

  def initialize(nonrating_issue_category:, decision_text: nil, decision_date: nil, benefit_type:, notes: nil)
    super decision_text: decision_text, decision_date: decision_date, benefit_type: benefit_type, notes: notes
    @nonrating_issue_category = nonrating_issue_category
    is_nonrating_issue_category? nonrating_issue_category, key: :nonrating_issue_category
  end

  def complete_hash
    super.merge nonrating_issue_category: nonrating_issue_category
  end

  private

  def validate_nonrating_issue_category
    unless nonrating_issue_category.in?(
      ::HigherLevelReviewRequest::NONRATING_ISSUE_CATEGORIES[benefit_type]
    )
      fail ArgumentError, "that nonrating_issue_category is invalid for that benefit_type"
    end
  end
end
