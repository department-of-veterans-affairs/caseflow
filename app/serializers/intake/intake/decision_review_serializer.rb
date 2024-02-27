# frozen_string_literal: true

class Intake::DecisionReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :claimant, &:claimant_participant_id
  attribute :claimant_type
  attribute :claimant_name do |object|
    object.claimant&.name
  end
  attribute :veteran_is_not_claimant
  attribute :processed_in_caseflow, &:processed_in_caseflow?
  attribute :legacy_opt_in_approved
  attribute :legacy_appeals, &:serialized_legacy_appeals
  attribute :ratings, &:serialized_ratings
  attribute :edit_issues_url, &:caseflow_only_edit_issues_url
  attribute :processed_at, &:establishment_processed_at
  attribute :veteran_invalid_fields
  attribute :request_issues, &:request_issues_ui_hash

  attribute :decision_issues do |object|
    object.decision_issues.map(&:serialize)
  end

  attribute :active_nonrating_request_issues do |object|
    object.active_nonrating_request_issues.map(&:serialize)
  end

  attribute :contestable_issues_by_date do |object|
    object.contestable_issues.map(&:serialize)
  end

  attribute :intake_user do |object|
    object.asyncable_user&.css_id
  end

  attribute :relationships do |object|
    object.veteran&.relationships&.map(&:serialize)
  end

  attribute :veteran_valid do |object|
    object.veteran&.valid?(:bgs)
  end

  attribute :receipt_date do |object|
    object.receipt_date&.to_formatted_s(:json_date)
  end

  attribute :veteran do |object|
    {
      name: object.veteran&.name&.formatted(:readable_short),
      fileNumber: object.veteran_file_number,
      formName: object.veteran&.name&.formatted(:form),
      ssn: object.veteran&.ssn
    }
  end

  attribute :power_of_attorney_name do |object|
    object.claimant&.power_of_attorney&.representative_name&.titleize
  end

  attribute :claimant_relationship do |object|
    object.claimant&.relationship&.titleize
  end
end
