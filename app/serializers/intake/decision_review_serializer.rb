# frozen_string_literal: true

class Intake::DecisionReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :claimant, &:claimant_participant_id
  attribute :veteranIsNotClaimant, &:veteran_is_not_claimant
  attribute :processedInCaseflow, &:processed_in_caseflow?
  attribute :legacyOptInApproved, & :legacy_opt_in_approved
  attribute :legacyAppeals, &:serialized_legacy_appeals
  attribute :ratings, &:serialized_ratings
  attribute :editIssuesUrl, &:caseflow_only_edit_issues_url
  attribute :processedAt, &:establishment_processed_at

  attribute :decision_issues do |object|
    object.decision_issues.map(&:serialize)
  end

  attribute :veteranInvalidFields do |object|
    object.send(:veteran_invalid_fields)
  end

  attribute :requestIssues do |object|
    object.send(:request_issues_ui_hash)
  end

  attribute :active_nonrating_request_issues do |object|
    object.active_nonrating_request_issues.map(&:serialize)
  end

  attribute :contestable_issues do |object|
    object.contestable_issues.map(&:serialize)
  end

  attribute :asyncable_user do |object|
    object.asyncable_user&.css_id
  end

  attribute :relationships do |object|
    object.veteran&.relationships&.map(&:serialize)
  end

  attribute :veteranValid do |object|
    object.veteran&.valid?(:bgs)
  end

  attribute :receiptDate do |object|
    object.receipt_date.to_formatted_s(:json_date)
  end

  attribute :veteran do |object|
    {
      name: object.veteran&.name&.formatted(:readable_short),
      fileNumber: object.veteran_file_number,
      formName: object.veteran&.name&.formatted(:form),
      ssn: object.veteran&.ssn
    }
  end
end
