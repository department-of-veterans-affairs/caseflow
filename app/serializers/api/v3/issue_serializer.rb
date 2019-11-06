# frozen_string_literal: true

class Api::V3::IssueSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  self.record_type = "Issue" #ContestableIssue?  Multiple serializers, need ids
end
