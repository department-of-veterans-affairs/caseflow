# frozen_string_literal: true

class HigherLevelReviewRequest::RatingIssueReference < HigherLevelReviewRequest::Reference
  alias contested_rating_issue_reference_id id
  alias rating_issue_reference_id id

  def complete_hash
    {
      rating_issue_reference_id: rating_issue_reference_id,
      notes: notes
    }
  end
end
