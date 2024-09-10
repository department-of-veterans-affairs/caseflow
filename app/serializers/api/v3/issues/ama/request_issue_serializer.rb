# frozen_string_literal: true

# use via `Api::V3::Issues::Ama::RequestIssueSerializer.new(<request issue obj>,
#                 include: [:decision_issues]).serializable_hash.to_json`
# or for a relation example:
#   `Api::V3::Issues::Ama::RequestIssueSerializer.new(
#       RequestIssue.includes(:decision_issues).where(veteran_participant_id: "574727696"), include: [:decision_issues]
#   ).serializable_hash.to_json`
# or with pagination:
#   `Api::V3::Issues::Ama::RequestIssueSerializer.new(
#      RequestIssue.includes(:decision_issues).page(2), include: [:decision_issues]
#   ).serializable_hash.to_json`
require "time"
class Api::V3::Issues::Ama::RequestIssueSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :benefit_type, :closed_at, :closed_status, :contention_reference_id, :contested_decision_issue_id,
             :contested_issue_description, :contested_rating_decision_reference_id,
             :contested_rating_issue_diagnostic_code, :contested_rating_issue_profile_date,
             :contested_rating_issue_reference_id, :corrected_by_request_issue_id,
             :correction_type, :created_at, :decision_date, :decision_review_id,
             :decision_review_type, :edited_description, :end_product_establishment_id,
             :ineligible_due_to_id, :ineligible_reason, :is_unidentified,
             :nonrating_issue_bgs_id, :nonrating_issue_category,
             :nonrating_issue_bgs_source, :nonrating_issue_description,
             :notes, :ramp_claim_id, :split_issue_status, :unidentified_issue_text,
             :untimely_exemption, :untimely_exemption_notes, :updated_at, :vacols_id,
             :vacols_sequence_id, :verified_unidentified_issue, :veteran_participant_id

  attribute :caseflow_considers_decision_review_active, &:status_active?
  attribute :caseflow_considers_issue_active, &:active?
  attribute :caseflow_considers_title_of_active_review, &:title_of_active_review
  attribute :caseflow_considers_eligible, &:eligible?

  attribute :claimant_participant_id do |object|
    object.decision_review.claimant.participant_id
  end

  attribute :claim_id do |object|
    object&.end_product_establishment&.reference_id
  end

  attribute :claim_errors do |object|
    claim_id = object&.end_product_establishment&.reference_id
    if claim_id
      Event.find_errors_by_claim_id(claim_id)
    else
      []
    end
  end

  attribute :decision_issues do |object|
    object.decision_issues.map do |di|
      {
        id: di.id,
        caseflow_decision_date: di.caseflow_decision_date,
        created_at: di.created_at,
        decision_text: di.decision_text,
        deleted_at: di.deleted_at,
        description: di.description,
        diagnostic_code: di.diagnostic_code,
        disposition: di.disposition,
        end_product_last_action_date: di.end_product_last_action_date,
        percent_number: di.percent_number,
        rating_issue_reference_id: di.rating_issue_reference_id,
        rating_profile_date: format_rating_profile_date(di.rating_profile_date),
        rating_promulgation_date: di.rating_promulgation_date,
        subject_text: di.subject_text,
        updated_at: di.updated_at
      }
    end
  end

  attribute :development_item_reference_id do |object|
    object&.end_product_establishment&.development_item_reference_id
  end

  attribute :same_office do |object|
    HigherLevelReview.find_by(veteran_file_number: object&.veteran&.file_number)&.same_office
  end

  attribute :legacy_opt_in_approved do |object|
    object&.decision_review&.legacy_opt_in_approved
  end

  attribute :added_by_station_id do |object|
    object&.added_by_user&.station_id
  end

  attribute :added_by_css_id do |object|
    object&.added_by_user&.css_id
  end

  attribute :edited_by_station_id do |object|
    object&.edited_by_user&.station_id
  end

  attribute :edited_by_css_id do |object|
    object&.edited_by_user&.css_id
  end

  attribute :removed_by_css_id do |object|
    object&.removed_by_user&.css_id
  end

  attribute :removed_by_station_id do |object|
    object&.removed_by_user&.station_id
  end

  attribute :withdrawn_by_css_id do |object|
    object&.withdrawn_by_user&.css_id
  end

  attribute :withdrawn_by_station_id do |object|
    object&.withdrawn_by_user&.station_id
  end

  def self.format_rating_profile_date(date)
    return nil if date.blank?

    begin
      return Time.parse(date).utc if date.is_a?(String)
    rescue ArgumentError
      return date.to_s
    end

    date.utc
  end
end
