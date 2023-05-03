# frozen_string_literal: true

class Intake::LegacyAppealSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :claimant, &:claimant_participant_id
  attribute :claimant_type do |object|
    object.claimant[:representative][:type]
  end
  attribute :claimant_name do |object|
    object.veteran_full_name
  end
  attribute :veteran_is_not_claimant
  attribute :processed_in_caseflow, &:processed_in_caseflow?
  attribute :legacy_opt_in_approved
  attribute :legacy_appeals, &:serialized_legacy_appeals
  attribute :ratings, &:serialized_ratings
  attribute :edit_issues_url, &:caseflow_only_edit_issues_url
  attribute :processed_at, &:establishment_processed_at
  attribute :veteran_invalid_fields
  attribute :request_issues, &:issues
  attribute :active_nonrating_request_issues
  attribute :contestable_issues_by_date
  attribute :intake_user

  attribute :decision_issues do |object|
    object.veteran.decision_issues.map(&:serialize)
  end

  attribute :relationships do |object|
    object.veteran&.relationships&.map(&:serialize)
  end

  attribute :veteran_valid do |object|
    object.veteran&.valid?(:bgs)
  end

  attribute :receipt_date

  attribute :veteran do |object|
    {
      name: object.veteran&.name&.formatted(:readable_short),
      fileNumber: object.veteran_file_number,
      formName: object.veteran&.name&.formatted(:form),
      ssn: object.veteran&.ssn
    }
  end

  attribute :power_of_attorney_name do |object|
    nil
  end

  attribute :claimant_relationship do |object|
    nil
  end

  attribute :docket_type do
    "Legacy"
  end

  attribute :is_outcoded do
    nil
  end

  attribute :form_type do
    "appeal"
  end
end
