# frozen_string_literal: true

class RequestIssueCorrection
  def initialize(review:, request_issues_data:)
    @review = review
    @request_issues_data = request_issues_data
  end

  def call
    return if corrected_issues.empty?

    # For now all corrected request issues should have the same correction label
    correction_claim_label = corrected_issue_data.first[:correction_claim_label]
    corrected_issues.each { |ri| ri.correct!(correction_claim_label) }
  end

  def corrected_issues
    @corrected_issues ||= calculate_corrected_issues
  end

  private

  attr_reader :review, :request_issues_data

  def calculate_corrected_issues
    corrected_issue_data.map do |issue_data|
      review.find_or_build_request_issue_from_intake_data(issue_data)
    end
  end

  def corrected_issue_data
    return [] unless request_issues_data

    request_issues_data.select { |ri| !ri[:correction_claim_label].nil? }
  end
end
