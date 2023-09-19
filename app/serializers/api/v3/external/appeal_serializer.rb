# frozen_string_literal: true

class Api::V3::External::AppealSerializer
  include FastJsonapi::ObjectSerializer
  set_type :appeal
  attributes *Appeal.column_names

  attribute :request_issues do |appeal|
    appeal.request_issues.map do |ri|
      ::Api::V3::External::RequestIssueSerializer.new(ri)
    end
  end
end
