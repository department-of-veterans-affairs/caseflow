# frozen_string_literal: true

class RampIssueSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :description
end
