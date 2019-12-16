# frozen_string_literal: true

class Intake::ClaimReviewSerializer < Intake::DecisionReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :async_job_url
  attribute :benefit_type
  attribute :payee_code
  attribute :has_cleared_rating_ep, &:cleared_rating_ep?
  attribute :has_cleared_nonrating_ep, &:cleared_nonrating_ep?
end
