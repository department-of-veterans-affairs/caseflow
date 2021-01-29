# frozen_string_literal: true

class ContestableIssueGenerator
  def initialize(review)
    @review = review
  end

  delegate :finalized_decision_issues_before_receipt_date, to: :review
  delegate :receipt_date, to: :review

  def contestable_issues
    contestable_rating_issues + contestable_decision_issues + contestable_rating_decisions
  end

  def contestable_rating_issues
    return [] unless review.can_contest_rating_issues?

    from_ratings.reject { |contestable_issue| decision_issue_duplicate_exists?(contestable_issue) }
  end

  def contestable_decision_issues
    issues = []
    issues += finalized_decision_issues_before_receipt_date unless review.try(:decision_review_remanded?)

    # If correction support enabled, we include all decision issues for the issue
    if FeatureToggle.enabled?(:correct_claim_reviews, user: RequestStore[:current_user])
      issues += review.decision_issues.select(&:finalized?)
    end

    @contestable_decision_issues ||= issues.map do |decision_issue|
      ContestableIssue.from_decision_issue(decision_issue, review)
    end
  end

  private

  attr_reader :review

  def contestable_rating_decisions
    return [] unless review.can_contest_rating_issues?
    return from_rating_decisions if FeatureToggle.enabled?(:disability_issue_test, user: RequestStore[:current_user])
    return [] unless FeatureToggle.enabled?(:contestable_rating_decisions, user: RequestStore[:current_user])

    from_rating_decisions.reject { |contestable_issue| decision_issue_duplicate_exists?(contestable_issue) }
  end

  def from_ratings
    return [] unless receipt_date

    issues = rating_issues

    unless FeatureToggle.enabled?(:show_future_ratings, user: RequestStore[:current_user])
      issues = issues.select { |issue| issue.profile_date && issue.profile_date.to_date <= receipt_date }
    end

    issues.map { |rating_issue| ContestableIssue.from_rating_issue(rating_issue, review) }
  end

  def from_rating_decisions
    return [] unless receipt_date

    if FeatureToggle.enabled?(:disability_issue_test, user: RequestStore[:current_user])
      return rating_decisions.map { |rating_decision| ContestableIssue.from_rating_decision(rating_decision, review) }
    end

    # rating decisions are a superset of every disability ever recorded for a veteran,
    # so filter out any that are duplicates of a rating issue or that are not related to their parent rating.
    rating_decisions
      .select(&:contestable?)
      .select { |rating_decision| rating_decision.profile_date && rating_decision.profile_date.to_date <= receipt_date }
      .map { |rating_decision| ContestableIssue.from_rating_decision(rating_decision, review) }
  end

  def rating_issues
    rating_hash_deserialize(from: :issues, to: RatingIssue)
  end

  def rating_decisions
    rating_hash_deserialize(from: :decisions, to: RatingDecision)
  end

  def rating_hash_deserialize(from:, to:)
    ratings.inject([]) do |result, rating_hash|
      result + rating_hash[from].map { |hash| to.deserialize(hash) }
    end
  end

  def decision_issue_duplicate_exists?(contestable_issue)
    contestable_decision_issues.any? do |potential_duplicate|
      contestable_issue.rating_issue_reference_id == potential_duplicate.rating_issue_reference_id
    end
  end

  def ratings
    review.cached_serialized_ratings
  end
end
