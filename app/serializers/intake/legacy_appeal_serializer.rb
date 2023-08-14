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
  attribute :request_issues, &:issues

  attribute :intake_user

  attribute :processed_in_caseflow do |object|
    true
  end

  attribute :legacy_opt_in_approved do |object|
    true
  end

  attribute :legacy_appeals do |object|
    []
  end

  attribute :ratings do |object|
    []
  end

  attribute :edit_issues_url do |object|
    "/appeals/#{object.id}/edit"
  end

  attribute :processed_at do |object|
    nil
  end

  attribute :veteran_invalid_fields do |object|
    nil
  end

  attribute :active_nonrating_request_issues do |object|
    []
  end

  attribute :contestable_issues_by_date do |object|
    []
  end

  attribute :intake_user do |object|
    nil
  end

  attribute :receipt_date do |object|
    nil
  end

  attribute :decision_issues do |object|
    object.veteran.decision_issues.map(&:serialize)
  end

  attribute :relationships do |object|
    object.veteran&.relationships&.map(&:serialize)
  end

  attribute :veteran_valid do |object|
    object.veteran&.valid?(:bgs)
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
