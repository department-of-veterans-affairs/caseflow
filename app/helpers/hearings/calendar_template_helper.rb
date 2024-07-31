# frozen_string_literal: true

##
# Helpers for use inside a template for a calendar invite or
# email related to virtual hearings.

module Hearings::CalendarTemplateHelper
  class << self
    # "Monday, 9 March 2020 at 5:10pm UTC"
    HEARING_TIME_DISPLAY_FORMAT = "%A, %-d %B %Y at %-l:%M%P %Z"

    def format_hearing_time(time)
      time.strftime("%A, %B #{time.day} %Y at %-l:%M%P %Z")
    end

    def central_office_display_time(hearing)
      format_hearing_time(hearing.time.central_office_time)
    end

    def representative_display_time(hearing)
      format_hearing_time(hearing.time.poa_time)
    end

    def appellant_display_time(hearing)
      format_hearing_time(hearing.time.appellant_time)
    end

    # time_zone is a TZInfo::DataTimezone object; date_time_utc is a Time object
    def formatted_date_time_for_zone(time_zone, date_time_utc)
      time_zone.strftime(HEARING_TIME_DISPLAY_FORMAT, date_time_utc)
    end

    def hearing_date_only(hearing)
      datetime = hearing.scheduled_for
      datetime.strftime("%a, %b %I") #  Fri, Mar 26
    end

    # hearing time in poa timezone
    def poa_time
      # Check if there's a recipient, and if it has a timezone, it it does use that to set tz
      representative_tz_from_recipient = hearing.representative_recipient&.timezone
      return normalized_time(representative_tz_from_recipient) if representative_tz_from_recipient.present?
      # If there's a virtual hearing, use that tz even if it's empty
      return normalized_time(hearing.virtual_hearing[:representative_tz]) if hearing.virtual_hearing.present?

      # No recipient and no virtual hearing? Use the normalized_time fallback
      normalized_time(nil)
    end

    # hearing time in appellant timezone
    def appellant_time
      # Check if there's a recipient, and if it has a timezone, it it does use that to set tz
      appellant_tz_from_recipient = hearing.appellant_recipient&.timezone
      return normalized_time(appellant_tz_from_recipient) if appellant_tz_from_recipient.present?
      # If there's a virtual hearing, use that tz even if it's empty
      return normalized_time(hearing.virtual_hearing[:appellant_tz]) if hearing.virtual_hearing.present?

      # No recipient and no virtual hearing? Use the normalized_time fallback
      normalized_time(nil)
    end

    def normalized_time(timezone)
      return hearing.time.local_time if timezone.nil?

      # throws an error here if timezone is invalid
      hearing.time.local_time.in_time_zone(timezone)
    end
  end
end
