# frozen_string_literal: true

class Intake::SupplementalClaimIntakeSerializer < Intake::ClaimReviewIntakeSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :filed_by_va_gov do |object|
    object.detail&.filed_by_va_gov
  end
end
