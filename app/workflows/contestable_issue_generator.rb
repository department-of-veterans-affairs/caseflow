# frozen_string_literal: true

class ContestableIssueGenerator
  def initialize(review)
    @review = review
  end

  delegate :finalized_decision_issues_before_receipt_date, to: :review
  delegate :receipt_date, to: :review

  def contestable_issues
    return contestable_decision_issues unless review.can_contest_rating_issues?

    contestable_ratings + contestable_decision_issues
  end

  private

  attr_reader :review

  def contestable_ratings
    from_ratings.reject { |contestable_issue| decision_issue_duplicate_exists?(contestable_issue) }
  end

  def contestable_decision_issues
    from_decision_issues.reject { |contestable_issue| contestable_issue.decision_issue&.voided? }
  end

  def from_ratings
    return [] unless receipt_date

    rating_issues_for_review
      .select { |issue| issue.profile_date && issue.profile_date.to_date < receipt_date }
      .map { |rating_issue| ContestableIssue.from_rating_issue(rating_issue, review) }
  end

  def from_decision_issues
    @from_decision_issues ||= finalized_decision_issues_before_receipt_date.map do |decision_issue|
      ContestableIssue.from_decision_issue(decision_issue, review)
    end
  end

  def rating_issues_for_review
    review.cached_serialized_ratings.inject([]) do |result, rating_hash|
      result + rating_hash[:issues].map { |rating_issue_hash| RatingIssue.deserialize(rating_issue_hash) }
    end
  end

  def decision_issue_duplicate_exists?(contestable_issue)
    from_decision_issues.any? do |potential_duplicate|
      contestable_issue.rating_issue_reference_id == potential_duplicate.rating_issue_reference_id
    end
  end
end
