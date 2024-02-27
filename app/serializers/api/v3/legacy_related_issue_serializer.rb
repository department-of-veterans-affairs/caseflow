# frozen_string_literal: true

class V3::LegacyRelatedIssueSerializer
  include FastJsonapi::ObjectSerializer

  attribute :summary, &:friendly_description
end
