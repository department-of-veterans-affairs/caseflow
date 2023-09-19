# frozen_string_literal: true

class Api::V3::External::AppealSerializer
  include FastJsonapi::ObjectSerializer
  set_type :appeal
  attributes *Appeal.column_names
  has_many :request_issues, serializer: Api::V3::External::RequestIssueSerializer
end
