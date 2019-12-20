# frozen_string_literal: true

require "icalendar"
require "icalendar/tzinfo"

##
# Service for creating calendar invites for use with the virtual hearings
# emails.

class VirtualHearings::CalendarService
  class << self
    def confirmation_calendar_invite(virtual_hearing, recipient, link)
      create_calendar_event(virtual_hearing, link) do |event, time_zone, start_time|
        template_context = {
          virtual_hearing: virtual_hearing,
          time_zone: time_zone,
          start_time_utc: start_time,
          link: link 
        }

        event.status = "CONFIRMED"
        event.summary = confirmation_summary(recipient)

        # Some * magic * here. The recipient title is used to determine
        # which template to load.
        event.description = render_virtual_hearing_calendar_event_template(
          "#{recipient.title.downcase}_confirmation_event_description",
          template_context
        )
      end
    end

    private

    def confirmation_summary(recipient)
      case recipient.title
      when MailRecipient::RECIPIENT_TITLES[:veteran], MailRecipient::RECIPIENT_TITLES[:representative]
        "Hearing with the Board of Veterans' Appeals"
      when MailRecipient::RECIPIENT_TITLES[:judge]
        "Virtual Hearing"
      end
    end

    def create_calendar
      cal = Icalendar::Calendar.new
      cal.prodid = "caseflow"
      cal
    end

    def create_calendar_event(virtual_hearing, link)
      cal = create_calendar
      start_time = virtual_hearing.hearing.scheduled_for
      end_time = start_time + 30.minutes
      tzid = virtual_hearing.hearing.regional_office_timezone
      tz = TZInfo::Timezone.get(tzid)

      cal.add_timezone(tz.ical_timezone(start_time))

      cal.event do |event|
        event.dtstart = Icalendar::Values::DateTime.new(start_time, tzid: tzid)
        event.dtend = Icalendar::Values::DateTime.new(end_time, tzid: tzid)
        event.url = link
        event.uid = "caseflow-virtual-hearing-conference-#{virtual_hearing.id}"

        yield event, tz, start_time
      end

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
end
