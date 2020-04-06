# frozen_string_literal: true

class RequestIssueCorrection
  def initialize(review:, corrected_request_issue_ids:, request_issues_data:)
    @corrected_request_issue_ids = corrected_request_issue_ids
    @review = review
    @request_issues_data = request_issues_data
  end

  delegate :end_product_establishment_for_issue, to: :review

  ATTRIBUTES_TO_COPY = %w[
    benefit_type
    contested_decision_issue_id
    contested_issue_description
    contested_rating_issue_diagnostic_code
    contested_rating_issue_profile_date
    contested_rating_issue_reference_id
    decision_date
    decision_review_id
    decision_review_type
    ineligible_due_to_id
    ineligible_reason
    is_unidentified
    nonrating_issue_category
    nonrating_issue_description
    notes
    ramp_claim_id
    unidentified_issue_text
    untimely_exemption
    untimely_exemption_notes
    covid_timeliness_exempt
    vacols_id
    vacols_sequence_id
    veteran_participant_id
    edited_description
    verified_unidentified_issue
  ].freeze

  def call
    return if corrected_issues.empty?

    corrected_issues.each do |ri|
      RequestIssueClosure.new(ri).with_no_decision!
      create_correction_issue!(ri)
    end
  end

  def corrected_issues
    @corrected_issues ||= @corrected_request_issue_ids.present? ? fetch_corrected_issues : calculate_corrected_issues
  end

  def correction_issues
    corrected_issues.map(&:correction_request_issue)
  end

  private

  attr_reader :request_issues_update, :review, :request_issues_data

  def fetch_corrected_issues
    RequestIssue.where(id: @corrected_request_issue_ids)
  end

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
    issue_data = corrected_issues_data.find { |ri| ri[:request_issue_id].to_i == original_issue.id }
    correction_type = issue_data[:correction_type]

    RequestIssue.create!(
      original_issue.attributes.slice(*ATTRIBUTES_TO_COPY).merge(correction_type: correction_type)
    ).tap do |correction_issue|
      correction_issue.update!(end_product_establishment: end_product_establishment_for_issue(correction_issue))
      original_issue.update!(correction_request_issue: correction_issue)
    end
  end
end
