# frozen_string_literal: true

class DecisionDateChecker < DataIntegrityChecker
  def call
    build_report
  end

  private

  def request_issues_without_decision_date
    RequestIssue.where
      .not(nonrating_issue_category: nil)
      .where(decision_date: nil, closed_at: nil)
  end

  def build_report
    return if request_issues_without_decision_date.empty?

    ids = request_issues_without_decision_date.map(&:id).sort
    count = ids.length

    add_to_report "Found #{count} Non-Rating Issues without decision date"
    add_to_report "RequestIssue.where(id: #{ids})"
  end
end
