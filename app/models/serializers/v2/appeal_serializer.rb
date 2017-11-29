class V2::AppealSerializer < ActiveModel::Serializer
  def id
    object.vacols_id
  end

  attribute :incomplete, key: :incomplete_history
  attribute :type_code, key: :type
  attribute :active?, key: :active
  attribute :aod
  attribute :location
  attribute :status_hash, key: :status
  attribute :alerts

  attribute :events do
    object.events.map(&:to_hash)
  end
end
