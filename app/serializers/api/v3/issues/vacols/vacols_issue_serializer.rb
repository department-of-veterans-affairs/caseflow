# frozen_string_literal: true

class Api::V3::Issues::VACOLS::VacolsIssueSerializer
  include FastJsonapi::ObjectSerializer

  # attributes :vacols_issue

  attributes :vacols_issue, &:vbms_attributes
end
