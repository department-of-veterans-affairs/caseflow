class V2::AppealSerializer < ActiveModel::Serializer
  def id
    object.vacols_id
  end

  attribute :vacols_ids, key: :appeal_ids

  attribute :updated do
    Time.zone.now.in_time_zone("Eastern Time (US & Canada)").round.iso8601
  end

  attribute :incomplete, key: :incomplete_history
  attribute :type_code, key: :type
  attribute :active?, key: :active
  attribute :description
  attribute :aod
  attribute :location
  attribute :aoj
  attribute :program, key: :program_area
  attribute :status_hash, key: :status
  attribute :alerts
  attribute :docket_hash, key: :docket
  attribute :issues

  attribute :events do
    object.events.map(&:to_hash)
  end

  # Stubbed attributes
  attribute :evidence do
    []
  end
end
