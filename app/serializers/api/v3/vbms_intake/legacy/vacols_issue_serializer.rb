# frozen_string_literal: true

class Api::V3::VbmsIntake::Legacy::VacolsIssueSerializer
  include JSONAPI::Serializer

  attribute :vacols_issue do |object|
    object.try(:vbms_attributes)
  end
end
