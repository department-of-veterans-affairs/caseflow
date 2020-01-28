# frozen_string_literal: true

module Helpers::AppealHearingHelper
  def available_hearing_locations(appeal)
    locations = appeal.available_hearing_locations || []

    locations.map do |ahl|
      {
        name: ahl.name,
        address: ahl.address,
        city: ahl.city,
        state: ahl.state,
        distance: ahl.distance,
        facility_id: ahl.facility_id,
        facility_type: ahl.facility_type,
        classification: ahl.classification,
        zip_code: ahl.zip_code,
        formatted_facility_type: ahl.formatted_facility_type
      }
    end
  end

  def hearings(appeal)
    appeal.hearings.map do |hearing|
      AppealHearingSerializer.new(hearing).serializable_hash[:data][:attributes]
    end
  end

  # returns the closest hearing location
  def suggested_hearing_location(appeal)
    available_hearing_locations(appeal).sort_by { |loc| loc[:distance] }.first
  end
end
