# frozen_string_literal: true

class Intake::SupplementalClaimSerializer < Intake::ClaimReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :isDtaError, &:decision_review_remanded?

  attribute :formType do
    "supplemental_claim"
  end
end