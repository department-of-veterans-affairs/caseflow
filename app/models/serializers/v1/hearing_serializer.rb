# frozen_string_literal: true

class V1::HearingSerializer < ActiveModel::Serializer
  attribute :type

  # Confirm with Chris, are times accurate for hearings?
  attribute :date do
    object.date.to_date
  end
end
