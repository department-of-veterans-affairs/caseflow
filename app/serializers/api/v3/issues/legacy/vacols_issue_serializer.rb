# frozen_string_literal: true

class Api::V3::Issues::Legacy::VacolsIssueSerializer
  include JSONAPI::Serializer

  # attributes :vacols_issue

  attributes :vacols_issue, &:vbms_attributes
end
