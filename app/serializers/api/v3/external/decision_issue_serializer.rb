# frozen_string_literal: true

class Api::V3::External::DecisionIssueSerializer
  include FastJsonapi::ObjectSerializer
  attributes(*DecisionIssue.column_names)
end
