# frozen_string_literal: true

##
# Helpers for use inside a template for a calendar invite or
# email related to virtual hearings.

module VirtualHearings::CalendarTemplateHelper
  class << self
    # "Monday, 9 March 2020 at 5:10pm UTC"
    HEARING_TIME_DISPLAY_FORMAT = "%A, %-d %B %Y at %-l:%M%P %Z"

    def central_office_display_time_for_virtual_hearing(virtual_hearing)
      virtual_hearing.hearing.time.central_office_time.strftime(HEARING_TIME_DISPLAY_FORMAT)
    end

    def local_display_time_for_virtual_hearing(virtual_hearing)
      virtual_hearing.hearing.time.local_time.strftime(HEARING_TIME_DISPLAY_FORMAT)
    end

    # time_zone is a TZInfo::DataTimezone object; date_time_utc is a Time object
    def formatted_date_time_for_zone(time_zone, date_time_utc)
      time_zone.strftime(HEARING_TIME_DISPLAY_FORMAT, date_time_utc)
    end
  end
end
