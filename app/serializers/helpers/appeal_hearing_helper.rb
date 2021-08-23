# frozen_string_literal: true

module Helpers::AppealHearingHelper
  def available_hearing_locations(appeal)
    locations = appeal.available_hearing_locations || []

    locations.map(&:to_hash)
  end

  def hearings(appeal, params)
    appeal.hearings.map do |hearing|
      AppealHearingSerializer.new(hearing, params).serializable_hash[:data][:attributes]
    end
  end
end
