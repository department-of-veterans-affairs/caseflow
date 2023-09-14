# frozen_string_literal: true

class Intake::RampIssueSerializer
  include JSONAPI::Serializer

  attribute :id
  attribute :description
end
