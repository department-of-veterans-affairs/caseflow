# frozen_string_literal: true

module StuckJobQueries

  def decision_documents_with_errors(error_text)
    DecisionDocument.where("error ILIKE ?", "%#{error_text}%")
  end

  def request_issues_updates_with_errors(error_text)
    RequestIssuesUpdate.where("error ILIKE?", "%#{error_text}%")
  end

  def board_grant_effectuations_with_errors(error_text)
    BoardGrantEffectuation.where("decision_sync_error ILIKE?", "%#{error_text}%")
  end

  def higher_level_review_with_errors(error_text)
    HigherLevelReview.where("establishment_error ILIKE?", "%#{error_text}%")
  end

  def supplemental_claims_with_errors(error_text)
    SupplementalClaim.where("establishment_error ILIKE ?", "%#{error_text}%")
  end
end

