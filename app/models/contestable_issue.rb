# Container class representing any type of issue that can be contested by a decision review
class ContestableIssue
  include ActiveModel::Model

  # approx_decision_date is our best guess at the decision date.
  # it is used for timeliness checks on the client side and for user display.
  attr_accessor :rating_issue_reference_id, :approx_decision_date, :description,
                :ramp_claim_id, :contesting_decision_review,
                :decision_issue_id, :rating_issue_profile_date, :source_request_issues,
                :rating_issue_diagnostic_code, :source_decision_review

  class << self
    def from_rating_issue(rating_issue, contesting_decision_review)
      new(
        rating_issue_reference_id: rating_issue.reference_id,
        rating_issue_profile_date: rating_issue.profile_date.to_date,
        approx_decision_date: rating_issue.promulgation_date.to_date,
        description: rating_issue.decision_text,
        ramp_claim_id: rating_issue.ramp_claim_id,
        contesting_decision_review: contesting_decision_review,
        rating_issue_diagnostic_code: rating_issue.diagnostic_code,

        # TODO: These should never be set unless there is a decision issue. We should refactor this to
        # account for that.
        source_request_issues: rating_issue.source_request_issues,
        source_decision_review: rating_issue.source_request_issues.first&.decision_review
      )
    end

    def from_decision_issue(decision_issue, contesting_decision_review)
      new(
        rating_issue_reference_id: decision_issue.rating_issue_reference_id,
        rating_issue_profile_date: decision_issue.profile_date.try(:to_date),
        decision_issue_id: decision_issue.id,
        approx_decision_date: decision_issue.approx_decision_date,
        description: decision_issue.description,
        source_request_issues: decision_issue.request_issues.open,
        source_decision_review: decision_issue.decision_review,
        contesting_decision_review: contesting_decision_review
      )
    end
  end

  def serialize
    {
      ratingIssueReferenceId: rating_issue_reference_id,
      ratingIssueProfileDate: rating_issue_profile_date,
      ratingIssueDiagnosticCode: rating_issue_diagnostic_code,
      decisionIssueId: decision_issue_id,
      approxDecisionDate: approx_decision_date,
      description: description,
      rampClaimId: ramp_claim_id,
      titleOfActiveReview: title_of_active_review,
      sourceReviewType: source_review_type,
      timely: timely?
    }
  end

  def source_review_type
    source_decision_review&.class&.name
  end

  # If a contestable issue is currently being reviewed by an open request issue on another decision review,
  # then this method returns the title of that review.
  def title_of_active_review
    conflicting_request_issue.try(:review_title)
  end

  private

  def decision_issue?
    !!decision_issue_id
  end

  def conflicting_request_issue_by_rating
    return unless rating_issue_reference_id

    potentially_conflicting_request_issues.find_active_by_contested_rating_issue_reference_id(rating_issue_reference_id)
  end

  def conflicting_request_issue_by_decision_issue
    return unless decision_issue_id

    potentially_conflicting_request_issues.find_active_by_contested_decision_id(decision_issue_id)
  end

  def potentially_conflicting_request_issues
    RequestIssue.where.not(decision_review: contesting_decision_review)
  end

  def conflicting_request_issue
    return unless contesting_decision_review

    found_request_issue = conflicting_request_issue_by_decision_issue || conflicting_request_issue_by_rating

    return unless different_decision_review(found_request_issue)

    found_request_issue
  end

  def different_decision_review(found_request_issue)
    return unless found_request_issue

    found_request_issue.decision_review_id != contesting_decision_review.id ||
      found_request_issue.decision_review_type != contesting_decision_review.class.name
  end

  def timely?
    approx_decision_date && contesting_decision_review.timely_issue?(approx_decision_date)
  end
end
