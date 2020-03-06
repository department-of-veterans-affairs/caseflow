# frozen_string_literal: true

##
# Helpers for use inside a template for a calendar invite related to
# virtual hearings.

module VirtualHearings::CalendarTemplateHelper
  def formatted_date_time_for_zone(time_zone, date_time_utc)
    time_zone.strftime("%A, %-d %B %Y at %-l:%M %p %Z", date_time_utc)
  end
end
