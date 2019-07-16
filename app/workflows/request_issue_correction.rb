# frozen_string_literal: true

class RequestIssueCorrection
  def initialize(review:, request_issues_data:)
    @review = review
    @request_issues_data = request_issues_data
  end

  def call
    corrected_issue_data.each do |issue_data|
      request_issue_to_correct = RequestIssue.find_by(id: issue_data.delete(:corrected_request_issue_id))
      new_issue = review.find_or_build_request_issue_from_intake_data(issue_data)
      request_issue_to_correct&.update(corrected_by_request_issue_id: new_issue.id)
    end
  end

  private

  attr_reader :review, :request_issues_data

  def corrected_issue_data
    return [] unless request_issues_data

    request_issues_data.select { |ri| !ri[:correction_claim_label].nil? }
  end
end
