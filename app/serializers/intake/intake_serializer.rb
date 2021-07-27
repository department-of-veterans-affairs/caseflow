# frozen_string_literal: true

class Intake::IntakeSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :form_type
  attribute :veteran_file_number
  attribute :completed_at

  attribute :veteran_form_name do |object|
    object.veteran&.name&.formatted(:form)
  end

  attribute :veteran_name do |object|
    object.veteran&.name&.formatted(:readable_short)
  end

  attribute :veteran_is_deceased do |object|
    object.veteran&.deceased?
  end

  attribute :relationships do |object|
    object.veteran&.relationships&.map(&:serialize)
  end

  attribute :receipt_date do |object|
    object.detail&.receipt_date
  end

  attribute :filed_by_va_gov do |object|
    object.detail&.filed_by_va_gov
  end

  attribute :processedInCaseflow do |object|
    object.detail&.try(:processed_in_caseflow?)
  end

  attribute :claimantType do |object|
    object.detail&.try(:claimant_type)
  end
end
