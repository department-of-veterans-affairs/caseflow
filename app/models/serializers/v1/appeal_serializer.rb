class V1::AppealSerializer < ActiveModel::Serializer
  def id
    object.vacols_id
  end

  attribute :type_code, key: :type
  attribute :active?, key: :active

  attribute :prior_decision_date do
    object.prior_decision_date.try(:to_date)
  end

  attribute :events do
    object.events.map(&:to_hash)
  end

  # TODO: add hearings
  # has_many :scheduled_hearings, serializer: ::V1::HearingSerializer
end
