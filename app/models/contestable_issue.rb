# Container class representing any type of issue that can be contested by a decision review
class ContestableIssue
  include ActiveModel::Model

  attr_accessor :rating_issue_reference_id, :date, :description, :ramp_claim_id, :contesting_decision_review,
                :decision_issue, :promulgation_date, :rating_issue_profile_date, :source_request_issues,
                :rating_issue_diagnostic_code

  class << self
    def from_rating_issue(rating_issue, contesting_decision_review)
      new(
        rating_issue_reference_id: rating_issue.reference_id,
        rating_issue_profile_date: rating_issue.profile_date,
        date: rating_issue.profile_date.to_date,
        description: rating_issue.decision_text,
        ramp_claim_id: rating_issue.ramp_claim_id,
        source_request_issues: rating_issue.source_request_issues,
        contesting_decision_review: contesting_decision_review,
        rating_issue_diagnostic_code: rating_issue.diagnostic_code
      )
    end

    def from_decision_issue(decision_issue, contesting_decision_review)
      new(
        rating_issue_reference_id: decision_issue.rating_issue_reference_id,
        rating_issue_profile_date: decision_issue.profile_date,
        date: decision_issue.approx_decision_date,
        description: decision_issue.description,
        decision_issue: decision_issue,
        source_request_issues: decision_issue.request_issues.open,
        contesting_decision_review: contesting_decision_review
      )
    end
  end

  def serialize
    {
      ratingIssueReferenceId: rating_issue_reference_id,
      ratingIssueProfileDate: rating_issue_profile_date.try(:to_date),
      ratingIssueDiagnosticCode: rating_issue_diagnostic_code,
      decisionIssueId: decision_issue&.id,
      date: date,
      description: description,
      rampClaimId: ramp_claim_id,
      titleOfActiveReview: title_of_active_review,
      sourceReviewType: source_review_type,
      timely: timely?,
      latestIssuesInChain: serialize_latest_decision_issues
    }
  end

  def serialize_decision_id_and_date
    { id: decision_issue&.id, date: date }
  end

  def source_review_type
    return unless source_request_issues.first

    !decision_issue.nil? ? source_request_issues.first.decision_review_type : source_request_issues.first.review_request_type
  end

  def next_decision_issues
    contested_by_request_issue&.decision_issues
  end

  def latest_contestable_issues
    # walks up the chain of request & decision issues until it finds the latest
    # decision issue in the chain (which will be the issue itself if no later decision issues exist)
    @latest_contestable_issues ||= find_latest_contestable_issues
  end

  private

  def contested_by_request_issue
    RequestIssue.open.find_by(contested_rating_issue_reference_id: rating_issue_reference_id, contested_decision_issue_id: decision_issue&.id)
  end

  def serialize_latest_decision_issues
    latest_contestable_issues.map(&:serialize_decision_id_and_date).sort_by { |issue| issue[:date] }
  end

  def find_latest_contestable_issues
    return [self] if next_decision_issues.blank?

    next_decision_issues.map do |decision_issue|
      ContestableIssue.from_decision_issue(decision_issue, decision_issue.decision_review).latest_contestable_issues
    end.flatten
  end

  def title_of_active_review
    conflicting_request_issue.try(:review_title)
  end

  def conflicting_request_issue_by_rating
    return unless rating_issue_reference_id

    potentially_conflicting_request_issues.find_active_by_contested_rating_issue_reference_id(rating_issue_reference_id)
  end

  def conflicting_request_issue_by_decision_issue
    return unless decision_issue&.id

    potentially_conflicting_request_issues.find_active_by_contested_decision_id(decision_issue.id)
  end

  def potentially_conflicting_request_issues
    RequestIssue.where.not(review_request: contesting_decision_review)
  end

  def conflicting_request_issue
    return unless contesting_decision_review

    found_request_issue = conflicting_request_issue_by_decision_issue || conflicting_request_issue_by_rating

    return unless different_decision_review(found_request_issue)

    found_request_issue
  end

  def different_decision_review(found_request_issue)
    return unless found_request_issue

    found_request_issue.review_request_id != contesting_decision_review.id ||
      found_request_issue.review_request_type != contesting_decision_review.class.name
  end

  def timely?
    date && contesting_decision_review.timely_issue?(date)
  end
end
