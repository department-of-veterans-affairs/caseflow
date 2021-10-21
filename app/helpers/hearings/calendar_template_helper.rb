# frozen_string_literal: true

##
# Helpers for use inside a template for a calendar invite or
# email related to virtual hearings.

module Hearings::CalendarTemplateHelper
  class << self
    # "Monday, 9 March 2020 at 5:10pm UTC"
    HEARING_TIME_DISPLAY_FORMAT = "%A, %-d %B %Y at %-l:%M%P %Z"

    def format_hearing_time(time)
      time.strftime("%A, %B #{time.day.ordinalize} %Y at %-l:%M%P %Z")
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
  end
end
