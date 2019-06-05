# frozen_string_literal: true

class WithdrawnDecisionReviewPolicy
  delegate :request_issues, to: :decision_review

  def initialize(decision_review)
    @decision_review = decision_review
  end

  def satisfied?
    no_active_request_issues? && at_least_one_withdrawn_issue?
  end

  private

  attr_reader :decision_review

  def no_active_request_issues?
    request_issues.active.empty?
  end

  def at_least_one_withdrawn_issue?
    request_issues.withdrawn.any?
  end
end
