# frozen_string_literal: true

class V2::AppealStatusSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower
  set_type :appeal
  set_id :appeal_status_id

  attribute :appeal_ids, &:linked_review_ids

  attribute :updated do
    Time.zone.now.in_time_zone("Eastern Time (US & Canada)").round.iso8601
  end

  attribute :incomplete_history do
    false
  end

  attribute :type do
    "original"
  end

  attribute :active, &:active_status?
  attribute :description
  attribute :aod, &:advanced_on_docket?
  attribute :location
  attribute :aoj
  attribute :program_area, &:program
  attribute :status, &:status_hash
  attribute :alerts
  attribute :docket, &:docket_hash
  attribute :events
  attribute :issues, &:issues_hash

  # Stubbed attributes
  attribute :evidence do
    []
  end
end
