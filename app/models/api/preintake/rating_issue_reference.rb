# frozen_string_literal: true

# for creating a new rating issue

class Api::Preintake::RatingIssueReference < Api::Preintake::RequestIssue
  include Api::Validation

  attr_reader :contested_rating_issue_reference_id

  def initialize(contested_rating_issue_reference_id:)
    @contested_rating_issue_reference_id = contested_rating_issue_reference_id.to_s

    is_string? contested_rating_issue_reference_id, key: :contested_rating_issue_reference_id
  end

  def complete_hash
    super.merge(
      rating_issue_reference_id: contested_rating_issue_reference_id,
      rating_issue_diagnostic_code: nil,
    )
  end
end
