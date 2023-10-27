# frozen_string_literal: true

class Api::V3::VbmsIntake::Legacy::VacolsIssueSerializer
  include JSONAPI::Serializer

  set_type :issue
  attribute :id
  attribute :legacy_appeal do |object|
    object.appeal.try do |appeal|
      Api::V3::VbmsIntake::Legacy::VbmsLegacyAppealSerializer.new(appeal).serializable_hash
    end
  end
  attribute :vacols_issue, &:intake_attributes
end
