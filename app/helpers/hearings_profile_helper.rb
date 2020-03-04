# frozen_string_literal: true

module HearingsProfileHelper
  class << self
    def profile_data(current_user = nil)
      ama_hearings_details = []
      legacy_hearings_details = []
      Hearing.all.order(:id).each { |hearing| ama_hearings_details << hearing_detail(hearing) }
      LegacyHearing.all.order(:id).each { |hearing| legacy_hearings_details << hearing_detail(hearing) }

      {
        profile: profile(current_user),
        hearings: {
          ama_hearings: ama_hearings_details,
          legacy_hearings: legacy_hearings_details
        }
      }
    end

    private

    def profile(current_user = nil)
      {
        current_user_css_id: current_user&.css_id,
        current_user_timezone: current_user&.timezone,
        time_zone_name: Time.zone.name,
        config_time_zone: Rails.configuration.time_zone
      }
    end

    def hearing_detail(hearing)
      {
        id: hearing.id,
        type: hearing.class.name,
        external_id: hearing.external_id,
        created_by_timezone: hearing.created_by&.timezone,
        central_office_time_string: hearing.central_office_time_string,
        scheduled_time_string: hearing.scheduled_time_string,
        scheduled_for: hearing.scheduled_for,
        scheduled_time: hearing.scheduled_time
      }
    end
  end
end
