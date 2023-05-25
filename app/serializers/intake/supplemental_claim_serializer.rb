# frozen_string_literal: true

class Intake::SupplementalClaimSerializer < Intake::ClaimReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :is_dta_error, &:decision_review_remanded?
  attribute :filed_by_va_gov
  attribute :form_type do
    "supplemental_claim"
  end
end
