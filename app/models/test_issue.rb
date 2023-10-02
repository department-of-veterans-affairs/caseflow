# frozen_string_literal: true

class TestIssue
  attr_accessor :benefit_type, :closed_status, :contention_reference_id, :contested_decision_issue_id,
                :contested_issue_description, :contested_rating_decision_reference_id,
                :contested_rating_issue_diagnostic_code, :contested_rating_issue_profile_date,
                :contested_rating_issue_reference_id, :corrected_by_request_issue_id, :correction_type,
                :created_at, :decision_date, :decision_review_id, :decision_review_type, :edited_description,
                :end_product_establishment_id, :ineligible_due_to_id, :ineligible_reason, :is_unidentified,
                :nonrating_issue_category, :nonrating_issue_description, :notes, :ramp_claim_id,
                :rating_issue_associated_at, :split_issue_status, :unidentified_issue_text, :untimely_exemption,
                :untimely_exemption_notes, :updated_at, :vacols_id, :vacols_sequence_id,
                :verified_unidentified_issue, :veteran_participant_id, :deleted_at,
                :decision_text, :description, :disposition, :end_product_last_action_date, :percent_number,
                :rating_issue_reference_id, :rating_profile_date, :rating_promulgation_date, :subject_text,
                :request_issue_id, :decision_issue_id, :nonrating_issue_bgs_id

  def initialize(attributes = {})
    @request_issue_id = attributes[:request_issue_id]
    @decision_issue_id = attributes[:decision_issue_id]
    @benefit_type = attributes[:benefit_type]
    @closed_status = attributes[:closed_status]
    @contention_reference_id = attributes[:contention_reference_id]
    @contested_decision_issue_id = attributes[:contested_decision_issue_id]
    @contested_issue_description = attributes[:contested_issue_description]
    @contested_rating_decision_reference_id = attributes[:contested_rating_decision_reference_id]
    @contested_rating_issue_diagnostic_code = attributes[:contested_rating_issue_diagnostic_code]
    @contested_rating_issue_profile_date = attributes[:contested_rating_issue_profile_date]
    @contested_rating_issue_reference_id = attributes[:contested_rating_issue_reference_id]
    @corrected_by_request_issue_id = attributes[:corrected_by_request_issue_id]
    @correction_type = attributes[:correction_type]
    @created_at = attributes[:created_at]
    @decision_date = attributes[:decision_date]
    @decision_review_id = attributes[:decision_review_id]
    @decision_review_type = attributes[:decision_review_type]
    @edited_description = attributes[:edited_description]
    @end_product_establishment_id = attributes[:end_product_establishment_id]
    @ineligible_id = attributes[:ineligible_due_to_id]
    @ineligible_reason = attributes[:ineligible_reason]
    @is_unidentified = attributes[:is_unidentified]
    @nonrating_issue_bgs_id = attributes[:nonrating_issue_bgs_id]
    @nonrating_issue_category = attributes[:nonrating_issue_category]
    @nonrating_issue_description = attributes[:nonrating_issue_description]
    @notes = attributes[:notes]
    @ramp_claim_id = attributes[:ramp_claim_id]
    @rating_issue_associated_at = attributes[:rating_issue_associated_at]
    @split_issue_status = attributes[:split_issue_status]
    @unidentified_issue_text = attributes[:unidentified_issue_text]
    @untimely_ = attributes[:untimely_exemption]
    @untimely_exemption_notes = attributes[:untimely_exemption_notes]
    @updated_at = attributes[:updated_at]
    @vacols_id = attributes[:vacols_id]
    @vacols_sequence_id = attributes[:vacols_sequence_id]
    @verified_unidentified_issue = attributes[:verified_unidentified_issue]
    @veteran_participant_id = attributes[:veteran_participant_id]
    @deleted_at = attributes[:deleted_at]
    @decision_text = attributes[:decision_text]
    @description = attributes[:description]
    @diagnostic_code = attributes[:diagnostic_code]
    @disposition = attributes[:disposition]
    @end_product_last_action_date = attributes[:end_product_last_action_date]
    @percent_number = attributes[:percent_number]
    @rating_issue_reference_id = attributes[:rating_issue_reference_id]
    @rating_profile_date = attributes[:rating_profile_date]
    @rating_promulgation_date = attributes[:rating_promulgation_date]
    @subject_text = attributes[:subject_text]
  end
end
