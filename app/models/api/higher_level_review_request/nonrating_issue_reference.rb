# frozen_string_literal: true

class HigherLevelReviewRequest::NonratingIssueReference < HigherLevelReviewRequest::Reference
  alias contested_decision_issue_id id

  def complete_hash
    {
      contested_decision_issue_id: contested_decision_issue_id, # this might be wrong
      notes: notes
    }
  end
end
