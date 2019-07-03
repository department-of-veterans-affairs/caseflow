# frozen_string_literal: true

class WithdrawnDecisionReviewPolicy
  delegate :active_request_issues, :withdrawn_request_issues, to: :decision_review

  def initialize(decision_review)
    @decision_review = decision_review
  end

  def satisfied?
    no_active_request_issues? && at_least_one_withdrawn_issue?
  end

  private

  attr_reader :decision_review

  def no_active_request_issues?
    active_request_issues.empty?
  end

  def at_least_one_withdrawn_issue?
    withdrawn_request_issues.any?
  end
end
