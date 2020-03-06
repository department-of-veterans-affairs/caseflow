# frozen_string_literal: true

class Api::V3::ContestableIssueSerializer
  def initialize(contestable_issues)
    @contestable_issues = contestable_issues
  end

  def to_json(_)
    { data: @contestable_issues.map { |issue| contestable_issue_json(issue) } }.to_json
  end

  private

  def contestable_issue_json(contestable_issue)
    latest_issues_in_chain =
      contestable_issue.latest_contestable_issues.collect do |latest|
        { id: latest.decision_issue&.id, approxDecisionDate: latest.approx_decision_date }
      end
    attributes = {
      ratingIssueId: contestable_issue.rating_issue_reference_id,
      ratingIssueProfileDate: contestable_issue.rating_issue_profile_date,
      ratingIssueDiagnosticCode: contestable_issue.rating_issue_diagnostic_code,
      description: contestable_issue.description,
      isRating: contestable_issue.is_rating,
      latestIssuesInChain: latest_issues_in_chain,
      decisionIssueId: contestable_issue.decision_issue&.id,
      ratingDecisionId: contestable_issue.rating_decision_reference_id,
      approxDecisionDate: contestable_issue.approx_decision_date,
      rampClaimId: contestable_issue.ramp_claim_id,
      titleOfActiveReview: contestable_issue.title_of_active_review,
      sourceReviewType: contestable_issue.source_review_type,
      timely: contestable_issue.timely?
    }

    { type: "ContestableIssue", attributes: attributes }
  end
end
