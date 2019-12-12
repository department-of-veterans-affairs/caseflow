# frozen_string_literal: true

class Intake::ClaimReviewSerializer < Intake::DecisionReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :asyncJobUrl, &:async_job_url
  attribute :benefitType, &:benefit_type
  attribute :payeeCode, &:payee_code

  attribute :hasClearedRatingEp do |object|
    object.send(:cleared_rating_ep?)
  end

  attribute :hasClearedNonratingEp do |object|
    object.send(:cleared_nonrating_ep?)
  end
end
