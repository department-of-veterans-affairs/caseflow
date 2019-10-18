class Api::V3::DecisionIssueSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attributes :approx_decision_date, :decision_text, :description, :disposition, :finalized
end
