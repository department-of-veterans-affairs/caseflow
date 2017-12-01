class V2::AppealSerializer < ActiveModel::Serializer
  def id
    object.vacols_id
  end

  attribute :type_code, key: :type
  attribute :active?, key: :active

  attribute :events do
    object.events.map(&:to_hash)
  end
end
