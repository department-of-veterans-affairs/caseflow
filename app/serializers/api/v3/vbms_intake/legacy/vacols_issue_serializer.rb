# frozen_string_literal: true

class Api::V3::VbmsIntake::Legacy::VacolsIssueSerializer
  include JSONAPI::Serializer

  attributes :vacols_issue, &:vbms_attributes
end
