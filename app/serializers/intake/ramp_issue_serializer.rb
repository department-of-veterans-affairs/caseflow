# frozen_string_literal: true

class Intake::RampIssueSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :description
end
