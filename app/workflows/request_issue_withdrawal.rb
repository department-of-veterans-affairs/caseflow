# frozen_string_literal: true

class RequestIssueWithdrawal
  def initialize(user:, review:, request_issues_data:)
    @user = user
    @review = review
    @request_issues_data = request_issues_data
  end

  def call
    return if withdrawn_issues.empty?

    withdrawal_date = withdrawn_issue_data.first[:withdrawal_date]
    withdrawn_issues.each { |ri| ri.withdraw!(withdrawal_date) }
  end

  def withdrawn_issues
    @withdrawn_issues ||= calculate_withdrawn_issues
  end

  private

  attr_reader :user, :review, :request_issues_data

  def calculate_withdrawn_issues
    withdrawn_issue_data.map do |issue_data|
      review.find_or_build_request_issue_from_intake_data(issue_data)
    end
  end

  def withdrawn_issue_data
    return [] unless request_issues_data

    request_issues_data.select { |ri| !ri[:withdrawal_date].nil? && ri[:request_issue_id] }
  end
end
