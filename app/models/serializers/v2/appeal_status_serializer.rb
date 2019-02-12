class V2::AppealStatusSerializer < ActiveModel::Serializer
  type :appeal

  def id
    object.appeal_status_id
  end

  attribute :linked_review_ids, key: :appeal_ids

  attribute :updated do
    Time.zone.now.in_time_zone("Eastern Time (US & Canada)").round.iso8601
  end

  attribute :incomplete_history do
    false
  end

  attribute :type do
    "original"
  end

  attribute :active_status?, key: :active
  attribute :description
  attribute :advanced_on_docket, key: :aod
  attribute :location

  attribute :aoj do
    "other"
  end

  attribute :program, key: :program_area
  attribute :status_hash, key: :status
  attribute :alerts
  attribute :docket_hash, key: :docket
  attribute :issues
  attribute :events

  attribute :issues_hash, key: :issues

  # Stubbed attributes
  attribute :evidence do
    []
  end
end
