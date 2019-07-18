# frozen_string_literal: true

class RequestIssueCorrection
  def initialize(user:, review:, request_issues_data:)
    @user = user
    @review = review
    @request_issues_data = request_issues_data
  end

  delegate :end_product_establishment_for_issue, to: :review

  EXCLUDED_ATTRIBUTES = %w[
    id
    contention_reference_id
    closed_at
    closed_status
    created_at
    decision_sync_attempted_at
    decision_sync_error
    decision_sync_last_submitted_at
    decision_sync_processed_at
    decision_sync_submitted_at
    disposition
    end_product_establishment_id
    rating_issue_associated_at
  ].freeze

  def call
    return if corrected_issues.empty?

    corrected_issues.each do |ri|
      RequestIssueClosure.new(ri).with_no_decision!
      create_correction_issue!(ri)
    end
  end

  def corrected_issues
    @corrected_issues ||= calculate_corrected_issues
  end

  private

  attr_reader :user, :review, :request_issues_data

  def calculate_corrected_issues
    corrected_issues_data.map do |issue_data|
      review.find_or_build_request_issue_from_intake_data(issue_data)
    end
  end

  def corrected_issues_data
    return [] unless request_issues_data

    request_issues_data.select { |ri| !ri[:correction_type].nil? && ri[:request_issue_id] }
  end

  def create_correction_issue!(original_issue)
    issue_data = corrected_issues_data.find { |ri| ri[:request_issue_id] == original_issue.id.to_s }
    correction_type = issue_data[:correction_type]

    RequestIssue.create!(
      original_issue.attributes.except(*EXCLUDED_ATTRIBUTES).merge(correction_type: correction_type)
    ).tap do |correction_issue|
      correction_issue.update!(end_product_establishment: end_product_establishment_for_issue(correction_issue))
      original_issue.update!(correction_request_issue: correction_issue)
    end
  end
end
