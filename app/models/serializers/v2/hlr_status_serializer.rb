class V2::HLRStatusSerializer < ActiveModel::Serializer
  type :higher_level_review

  def id
    object.review_status_id
  end

  attribute :linked_review_ids, key: :appeal_ids

  attribute :updated do
    Time.zone.now.in_time_zone("Eastern Time (US & Canada)").round.iso8601
  end

  attribute :incomplete_history do
    false
  end

  attribute :active_status?, key: :active
  attribute :description

  attribute :location do
    "aoj"
  end

  attribute :aoj
  attribute :program, key: :program_area
  attribute :status_hash, key: :status
  attribute :alerts
  attribute :issues_hash, key: :issues
  attribute :events

  # Stubbed attributes
  attribute :evidence do
    []
  end
end
