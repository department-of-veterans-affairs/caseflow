# frozen_string_literal: true

require "icalendar"
require "icalendar/tzinfo"

##
# Service for creating calendar invites for use with the virtual hearings
# emails.

class Hearings::CalendarService
  class << self
    # Sent when first switching a video hearing to a virtual hearing,
    # and also when the scheduled time for an existing virtual hearing
    # is changed.
    def confirmation_calendar_invite(virtual_hearing, recipient, link)
      create_calendar_event(virtual_hearing.hearing) do |event, time_zone, start_time|
        template_context = {
          virtual_hearing: virtual_hearing,
          time_zone: time_zone,
          start_time_utc: start_time,
          link: link
        }

        event.url = link
        event.location = link
        event.status = "CONFIRMED"
        event.summary = summary(recipient)
        event.description = render_virtual_hearing_calendar_event_template(
          recipient, :confirmation, template_context
        )
      end
    end

    # Sent when a virtual hearing is switched back to a video hearing.
    def update_to_video_calendar_invite(virtual_hearing, recipient)
      create_calendar_event(virtual_hearing.hearing) do |event, time_zone, start_time|
        if recipient.title == MailRecipient::RECIPIENT_TITLES[:judge]
          # For judges, just cancel the original invitation.
          event.status = "CANCELLED"
        else
          template_context = {
            virtual_hearing: virtual_hearing,
            time_zone: time_zone,
            start_time_utc: start_time
          }

          event.status = "CONFIRMED"
          event.summary = summary(recipient)
          event.description = render_virtual_hearing_calendar_event_template(
            recipient, :changed_to_video, template_context
          )
        end
      end
    end

    private

    def summary(recipient)
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

    def create_calendar_event(hearing)
      cal = create_calendar
      start_time = hearing.time.local_time
      end_time = start_time + 30.minutes
      tzid = hearing.regional_office_timezone
      tz = TZInfo::Timezone.get(tzid)

      cal.add_timezone(tz.ical_timezone(start_time))

      cal.event do |event|
        event.dtstart = Icalendar::Values::DateTime.new(start_time, tzid: tzid)
        event.dtend = Icalendar::Values::DateTime.new(end_time, tzid: tzid)

        # Assumption: expecting there to be at most one active virtual hearing
        # associated with a hearing at any given time.
        event.uid = "caseflow-hearing-conference-#{hearing.id}"

        yield event, tz, start_time.utc
      end

      cal.to_ical
    end

    def render_virtual_hearing_calendar_event_template(recipient, event_type, locals)
      template = ActionView::Base.new(ActionMailer::Base.view_paths, {})
      template.class_eval do
        include Hearings::CalendarTemplateHelper
        include Hearings::AppellantNameHelper
      end

      # Some *~ magic ~* here. The recipient title is used to determine which template to load:
      #
      #              judge_confirmation_event_description
      #     representative_confirmation_event_description
      #            veteran_confirmation_event_description
      #
      # representative_changed_to_video_event_description
      #        veteran_changed_to_video_event_description

      template_name = "#{recipient.title.downcase}_#{event_type}_event_description"

      template.render(
        file: "hearing_mailer/calendar_events/#{template_name}",
        locals: locals
      )
    end
  end
end
