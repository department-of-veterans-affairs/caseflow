# Container class representing any type of issue that can be contested by a decision review
class ContestableIssue
  include ActiveModel::Model

  attr_accessor :rating_issue_reference_id, :date, :description, :ramp_claim_id, :title_of_active_review,
                :source_higher_level_review, :contesting_decision_review, :decision_issue_reference_id,
                :promulgation_date, :rating_issue_profile_date

  class << self
    def from_rating_issue(rating_issue, contesting_decision_review)
      new(
        rating_issue_reference_id: rating_issue.reference_id,
        rating_issue_profile_date: rating_issue.profile_date.to_date,
        date: rating_issue.profile_date.to_date,
        description: rating_issue.decision_text,
        ramp_claim_id: rating_issue.ramp_claim_id,
        source_higher_level_review: rating_issue.source_higher_level_review,
        contesting_decision_review: contesting_decision_review
      )
    end

    def from_decision_issue(decision_issue, contesting_decision_review)
      new(
        rating_issue_reference_id: decision_issue.rating_issue_reference_id,
        rating_issue_profile_date: decision_issue.profile_date && decision_issue.profile_date.to_date,
        decision_issue_reference_id: decision_issue.id,
        date: decision_issue.approx_decision_date,
        description: decision_issue.decision_text, # TODO: also work with disposition
        source_higher_level_review: decision_issue.source_higher_level_review,
        contesting_decision_review: contesting_decision_review
      )
    end
  end

  def serialize
    {
      ratingIssueReferenceId: rating_issue_reference_id,
      ratingIssueProfileDate: rating_issue_profile_date,
      decisionIssueReferenceId: decision_issue_reference_id,
      date: date,
      description: description,
      rampClaimId: ramp_claim_id,
      titleOfActiveReview: title_of_active_review,
      sourceHigherLevelReview: source_higher_level_review,
      timely: timely?
    }
  end

  private

  def title_of_active_review
    conflicting_request_issue && conflicting_request_issue.title_of_active_review
  end

  def conflicting_request_issue
    contesting_decision_review.request_issues.find_by(rating_issue_reference_id: rating_issue_reference_id)
  end

  def timely?
    date && contesting_decision_review.timely_issue?(date)
  end
end
