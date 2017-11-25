class V2::AppealSerializer < ActiveModel::Serializer
  def id
    object.vacols_id
  end

  attribute :incomplete, key: :incomplete_history
  attribute :type_code, key: :type
  attribute :active?, key: :active
  attribute :aod
  attribute :api_location, key: :location

  attribute :events do
    object.events.map(&:to_hash)
  end

  attribute :status do
    {
      type: object.api_status,
      details: details_for_status(object.api_status)
    }
  end

  def details_for_status(status_type)
    case status_type
    when :decision_in_progress
      { test: "Hello World" }
    else
      {}
    end
  end
end
