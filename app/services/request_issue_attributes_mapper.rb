# frozen_string_literal: true

class RequestIssueAttributesMapper
  def initialize(parser_issue, parser)
    @parser_issue = parser_issue
    @parser = parser
  end

  # rubocop:disable Metrics/MethodLength
  def call
    {
      ineligible_reason: @parser_issue.ri_ineligible_reason,
      closed_at: @parser_issue.ri_closed_at,
      closed_status: @parser_issue.ri_closed_status,
      contested_issue_description: @parser_issue.ri_contested_issue_description,
      nonrating_issue_category: @parser_issue.ri_nonrating_issue_category,
      nonrating_issue_description: @parser_issue.ri_nonrating_issue_description,
      contention_updated_at: @parser.end_product_establishment_last_synced_at,
      contention_reference_id: @parser_issue.ri_contention_reference_id,
      contested_decision_issue_id: @parser_issue.ri_contested_decision_issue_id,
      contested_rating_issue_reference_id: @parser_issue.ri_contested_rating_issue_reference_id,
      contested_rating_issue_diagnostic_code: @parser_issue.ri_contested_rating_issue_diagnostic_code,
      contested_rating_decision_reference_id: @parser_issue.ri_contested_rating_decision_reference_id,
      contested_rating_issue_profile_date: @parser_issue.ri_contested_rating_issue_profile_date,
      nonrating_issue_bgs_source: @parser_issue.ri_nonrating_issue_bgs_source,
      nonrating_issue_bgs_id: @parser_issue.ri_nonrating_issue_bgs_id,
      unidentified_issue_text: @parser_issue.ri_unidentified_issue_text,
      vacols_sequence_id: @parser_issue.ri_vacols_sequence_id,
      ineligible_due_to_id: @parser_issue.ri_ineligible_due_to_id,
      reference_id: @parser_issue.ri_reference_id,
      rating_issue_associated_at: @parser_issue.ri_rating_issue_associated_at,
      edited_description: @parser_issue.ri_edited_description,
      ramp_claim_id: @parser_issue.ri_ramp_claim_id,
      vacols_id: @parser_issue.ri_vacols_id,
      decision_date: @parser_issue.ri_decision_date,
      is_unidentified: @parser_issue.ri_is_unidentified,
      untimely_exemption: @parser_issue.ri_untimely_exemption,
      untimely_exemption_notes: @parser_issue.ri_untimely_exemption_notes,
      benefit_type: @parser_issue.ri_benefit_type,
      veteran_participant_id: @parser_issue.ri_veteran_participant_id
    }
  end
  # rubocop:enable Metrics/MethodLength
end
