# frozen_string_literal: true

# Container class representing any type of issue that can be contested by a decision review
class ContestableIssue
  include ActiveModel::Model

  # approx_decision_date is our best guess at the decision date.
  # it is used for timeliness checks on the client side and for user display.
  attr_accessor :rating_issue_reference_id, :approx_decision_date, :description,
                :ramp_claim_id, :contesting_decision_review, :is_rating,
                :decision_issue, :rating_issue_profile_date, :source_request_issues,
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
        is_rating: true,

        # TODO: These should never be set unless there is a decision issue. We should refactor this to
        # account for that.
        source_request_issues: rating_issue.source_request_issues,
        source_decision_review: rating_issue.source_request_issues.first&.decision_review
      )
    end

    def from_decision_issue(decision_issue, contesting_decision_review)
      new(
        rating_issue_reference_id: decision_issue.rating_issue_reference_id,
        rating_issue_profile_date: decision_issue.rating_profile_date.try(:to_date),
        approx_decision_date: decision_issue.approx_decision_date,
        description: decision_issue.description,
        decision_issue: decision_issue,
        source_request_issues: decision_issue.request_issues.active,
        source_decision_review: decision_issue.decision_review,
        contesting_decision_review: contesting_decision_review,
        is_rating: decision_issue.rating?
      )
    end
  end

  def serialize
    {
      ratingIssueReferenceId: rating_issue_reference_id,
      ratingIssueProfileDate: rating_issue_profile_date.try(:to_date),
      ratingIssueDiagnosticCode: rating_issue_diagnostic_code,
      decisionIssueId: decision_issue&.id,
      approxDecisionDate: approx_decision_date,
      description: description,
      rampClaimId: ramp_claim_id,
      titleOfActiveReview: title_of_active_review,
      sourceReviewType: source_review_type,
      timely: timely?,
      latestIssuesInChain: serialize_latest_decision_issues,
      isRating: is_rating
    }
  end

  def serialize_decision_id_and_date
    { id: decision_issue&.id, approxDecisionDate: approx_decision_date }
  end

  def source_review_type
    source_decision_review&.class&.name
  end

  def next_decision_issues
    contested_by_request_issue&.decision_issues
  end

  def latest_contestable_issues
    # walks up the chain of request & decision issues until it finds the latest
    # decision issue in the chain (which will be the issue itself if no later decision issues exist)
    @latest_contestable_issues ||= find_latest_contestable_issues
  end

  # If a contestable issue is currently being reviewed by an open request issue on another decision review,
  # then this method returns the title of that review. (e.g. "Appeal")
  def title_of_active_review
    conflicting_request_issue.try(:review_title)
  end

  private

  def contested_by_request_issue
    RequestIssue.active.find_by(
      contested_rating_issue_reference_id: rating_issue_reference_id,
      contested_decision_issue_id: decision_issue&.id
    )
  end

  def serialize_latest_decision_issues
    latest_contestable_issues.map(&:serialize_decision_id_and_date).sort_by { |issue| issue[:approxDecisionDate] }
  end

  def find_latest_contestable_issues
    return [self] if next_decision_issues.blank?

    next_decision_issues.map do |decision_issue|
      ContestableIssue.from_decision_issue(decision_issue, contesting_decision_review).latest_contestable_issues
    end.flatten
  end

  def conflicting_request_issue
    conflicting_request_issue_by_decision_issue || conflicting_request_issue_by_rating
  end

  def conflicting_request_issue_by_rating
    return unless rating_issue_reference_id

    potentially_conflicting_request_issues.find_by(contested_rating_issue_reference_id: rating_issue_reference_id)
  end

  def conflicting_request_issue_by_decision_issue
    return unless decision_issue&.id

    potentially_conflicting_request_issues.find_by(contested_decision_issue_id: decision_issue.id)
  end

  def potentially_conflicting_request_issues
    # RequestIssue.where.not(decision_review: contesting_decision_review) does not work as expected.
    # This will be fixed in Rails 6
    # see: https://github.com/rails/rails/commit/e9ba12f746b3d149bba252df84957a9c26ad170b
    RequestIssue.where(
      "decision_review_id != ? OR decision_review_type != ?",
      contesting_decision_review.id,
      contesting_decision_review.class.name
    ).active
  end

  def timely?
    approx_decision_date && contesting_decision_review.timely_issue?(approx_decision_date)
  end
end
