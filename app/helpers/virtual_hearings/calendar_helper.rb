# frozen_string_literal: true

require "icalendar"
require "icalendar/tzinfo"

##
# Helpers for creating calendar invites for use with the virtual hearings
# emails.

module VirtualHearings::CalendarHelper
  def confirmation_calendar_invite(recipient, virtual_hearing, link)
    create_calendar_event do |event, time_zone, start_time|
      end_time = start_time + 30.minutes

      event.dtstart = Icalendar::Values::DateTime.new(start_time, tzid: time_zone.identifier)
      event.dtend = Icalendar::Values::DateTime.new(end_time, tzid: time_zone.identifier)
      event.summary = "You're scheduled for a virtual hearing with a Veterans Law Judge of the Board of Veterans' Appeals."
      event.status = "CONFIRMED"
      event.url = link
      event.uid = "caseflow-virtual-hearing-conference-#{virtual_hearing.id}"
      event.description = render_virtual_hearing_calendar_event_template(
        "#{recipient.title}_confirmation_event_description",
        { virtual_hearing: virtual_hearing, time_zone: time_zone, start_time_utc: start_time, link: link }
      )
    end
  end

  private

  def create_calendar_event
    cal = Icalendar::Calendar.new
    cal.prodid = "caseflow"

    start_time = virtual_hearing.hearing.scheduled_for
    tzid = virtual_hearing.hearing.regional_office_timezone
    tz = TZInfo::Timezone.get(tzid)

    cal.add_timezone(tz.ical_timezone(start_time))

    cal.event { |event| yield event, tz, start_time }

    cal
  end

  def render_virtual_hearing_calendar_event_template(template_name, locals)
    template = ActionView::Base.new(ActionMailer::Base.view_paths, {})
    template.class_eval { include VirtualHearings::CalendarTemplateHelper }

    template.render(
      file: "virtual_hearing_mailer/calendar_events/#{template_name}",
      locals: locals
    )
  end
end
