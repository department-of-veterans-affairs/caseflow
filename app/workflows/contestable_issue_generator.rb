# frozen_string_literal: true

class ContestableIssueGenerator
  def initialize(review, participant_id)
    @review = review
    @participant_id = participant_id
  end

  def contestable_issues
    return [] unless review.receipt_date
    return filtered_from_decision_issues unless review.can_contest_rating_issues?

    filtered_from_ratings + filtered_from_decision_issues
  end

  private

  attr_reader :review, :participant_id

  def filtered_from_ratings
    unfiltered_from_ratings.reject do |contestable_issue|
      from_decision_issues.any? do |potential_duplicate|
        contestable_issue.rating_issue_reference_id == potential_duplicate.rating_issue_reference_id
      end
    end
  end

  def filtered_from_decision_issues
    from_decision_issues.reject(&:voided?)
  end

  def unfiltered_from_ratings
    cached_rating_issues
      .select { |issue| issue.profile_date && issue.profile_date.to_date < review.receipt_date }
      .map { |rating_issue| ContestableIssue.from_rating_issue(rating_issue, review) }
  end

  def from_decision_issues
    @from_decision_issues ||= finalized_decision_issues.map do |decision_issue|
      ContestableIssue.from_decision_issue(decision_issue, review)
    end
  end

  def finalized_decision_issues
    DecisionIssue.where(participant_id: participant_id, benefit_type: review.benefit_type)
      .select(&:finalized?)
      .select do |issue|
        issue.approx_decision_date && issue.approx_decision_date < review.receipt_date
      end
  end

  def cached_rating_issues
    review.cached_serialized_ratings.inject([]) do |result, rating_hash|
      result + rating_hash[:issues].map { |rating_issue_hash| RatingIssue.deserialize(rating_issue_hash) }
    end
  end
end
