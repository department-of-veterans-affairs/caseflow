# frozen_string_literal: true

class Api::V3::LegacyRelatedIssueSerializer
  include FastJsonapi::ObjectSerializer

  attribute :summary, &:friendly_description
end
