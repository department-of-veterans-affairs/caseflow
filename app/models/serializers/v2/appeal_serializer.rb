class V2::AppealSerializer < ActiveModel::Serializer
  def id
    object.vacols_id
  end

  attribute :incomplete, key: :incomplete_history
  attribute :type_code, key: :type
  attribute :active?, key: :active
  attribute :aod
  attribute :location
  attribute :aoj
  attribute :program, key: :program_area
  attribute :status_hash, key: :status
  attribute :alerts
  attribute :issues

  attribute :events do
    object.events.map(&:to_hash)
  end

  # Stubbed attributes
  attribute :description do
    ""
  end

  attribute :docket do
    nil
  end

  attribute :evidence do
    []
  end
end
