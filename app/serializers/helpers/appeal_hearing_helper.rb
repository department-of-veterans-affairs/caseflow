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
        zip_code: ahl.zip_code
      }
    end
  end

  def hearings(appeal)
    appeal.hearings.map do |hearing|
      {
        held_by: hearing.judge.present? ? hearing.judge.full_name : "",
        # this assumes only the assigned judge will view the hearing worksheet. otherwise,
        # we should check `hearing.hearing_views.map(&:user_id).include? judge.css_id`
        viewed_by_judge: !hearing.hearing_views.empty?,
        date: hearing.scheduled_for,
        type: hearing.readable_request_type,
        external_id: hearing.external_id,
        disposition: hearing.disposition
      }
    end
  end
end
