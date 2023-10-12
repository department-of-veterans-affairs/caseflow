# frozen_string_literal: true

class V3::DecisionIssueSerializer
  #include FastJsonapi::ObjectSerializer
  include JSONAPI::Serializer

  attributes :caseflow_decision_date, :created_at, :decision_text, :deleted_at,
             :description, :diagnostic_code, :disposition, :end_product_last_action_date,
             :percent_number, :rating_issue_reference_id, :rating_profile_date,
             :rating_promulgation_date, :subject_text, :updated_at
end
