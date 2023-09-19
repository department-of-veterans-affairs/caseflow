# frozen_string_literal: true

class Api::V3::External::DecisionIssueSerializer
  include FastJsonapi::ObjectSerializer
  set_type :decision_issue
  attributes *DecisionIssue.column_names
end
