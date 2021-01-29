# frozen_string_literal: true

class V2::LegacyAppealStatusSerializer
  include JSONAPI::Serializer
  include StatusFieldSerializer

  set_key_transform :camel_lower
  set_type :legacy_appeal
  set_id :vacols_id

  attribute :appeal_ids, &:vacols_ids

  attribute :updated do
    Time.zone.now.in_time_zone("Eastern Time (US & Canada)").round.iso8601
  end

  attribute :incomplete_history, &:incomplete
  attribute :type, &:type_code
  attribute :active, &:active?
  attribute :description
  attribute :aod
  attribute :location
  attribute :aoj
  attribute :program_area, &:program
  attribute :status do |object|
    status(object)
  end

  attribute :alerts
  attribute :docket, &:docket_hash
  attribute :issues

  attribute :events do |object|
    object.events.map(&:to_hash)
  end

  # Stubbed attributes
  attribute :evidence do
    []
  end
end
