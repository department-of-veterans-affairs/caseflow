# frozen_string_literal: true

class Intake::ClaimReviewIntakeSerializer < Intake::DecisionReviewIntakeSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attribute :detail_edit_url do |object|
    object.detail&.reload&.caseflow_only_edit_issues_url
  end

  attribute :async_job_url do |object|
    object.detail&.async_job_url
  end

  attribute :benefit_type do |object|
    object.detail.benefit_type
  end

  attribute :processed_in_caseflow do |object|
    object.detail.processed_in_caseflow?
  end
end
