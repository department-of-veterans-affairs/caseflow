# frozen_string_literal: true

class RequestIssueBuilder
  def initialize(parser_issue, end_product_establishment_id, decision_review)
    @parser_issue = parser_issue
    @end_product_establishment_id = end_product_establishment_id
    @decision_review = decision_review
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def build
    RequestIssue.create!(
      reference_id: @parser_issue.ri_reference_id,
      benefit_type: @parser_issue.ri_benefit_type,
      contested_issue_description: @parser_issue.ri_contested_issue_description,
      contention_reference_id: @parser_issue.ri_contention_reference_id,
      contested_rating_decision_reference_id: @parser_issue.ri_contested_rating_decision_reference_id,
      contested_rating_issue_profile_date: @parser_issue.ri_contested_rating_issue_profile_date,
      contested_rating_issue_reference_id: @parser_issue.ri_contested_rating_issue_reference_id,
      contested_decision_issue_id: @parser_issue.ri_contested_decision_issue_id,
      decision_date: @parser_issue.ri_decision_date,
      ineligible_due_to_id: @parser_issue.ri_ineligible_due_to_id,
      ineligible_reason: @parser_issue.ri_ineligible_reason,
      is_unidentified: @parser_issue.ri_is_unidentified,
      unidentified_issue_text: @parser_issue.ri_unidentified_issue_text,
      nonrating_issue_category: @parser_issue.ri_nonrating_issue_category,
      nonrating_issue_description: @parser_issue.ri_nonrating_issue_description,
      untimely_exemption: @parser_issue.ri_untimely_exemption,
      untimely_exemption_notes: @parser_issue.ri_untimely_exemption_notes,
      vacols_id: @parser_issue.ri_vacols_id,
      vacols_sequence_id: @parser_issue.ri_vacols_sequence_id,
      closed_at: @parser_issue.ri_closed_at,
      closed_status: @parser_issue.ri_closed_status,
      contested_rating_issue_diagnostic_code: @parser_issue.ri_contested_rating_issue_diagnostic_code,
      ramp_claim_id: @parser_issue.ri_ramp_claim_id,
      rating_issue_associated_at: @parser_issue.ri_rating_issue_associated_at,
      nonrating_issue_bgs_id: @parser_issue.ri_nonrating_issue_bgs_id,
      nonrating_issue_bgs_source: @parser_issue.ri_nonrating_issue_bgs_source,
      end_product_establishment_id: @end_product_establishment_id,
      veteran_participant_id: @parser_issue.ri_veteran_participant_id,
      decision_review: @decision_review
    )
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
