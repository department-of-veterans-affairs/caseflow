# frozen_string_literal: true

class Api::V3::LegacyRelatedIssueSerializer
  include JSONAPI::Serializer

  attribute :summary, &:friendly_description
end
