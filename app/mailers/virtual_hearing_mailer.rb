# frozen_string_literal: true

require "icalendar"
require "icalendar/tzinfo"

class VirtualHearingMailer < ActionMailer::Base
  default from: "solutions@public.govdelivery.com"
  layout "virtual_hearing_mailer"
  attr_reader :recipient, :virtual_hearing

  RECIPIENT_TITLES = {
    judge: "Judge",
    veteran: "Veteran",
    representative: "Representative"
  }.freeze

  def cancellation(mail_recipient:, virtual_hearing: nil)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing
    mail(to: recipient.email, subject: "Updated location: Your hearing with the Board of Veterans' Appeals")
  end

  def confirmation(mail_recipient:, virtual_hearing: nil)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing
    @link = link

    attachments['invite.ics']

    mail(to: recipient.email, subject: confirmation_subject)
  end

  def updated_time_confirmation(mail_recipient:, virtual_hearing: nil)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing
    @link = link
    mail(
      to: recipient.email,
      subject: "Updated time: Your virtual hearing with the Board of Veterans' Appeals"
    )
  end

  def confirmation_calendar_invite(virtual_hearing)
    @virtual_hearing = virtual_hearing

    cal = Icalendar::Calendar.new

    start_time = virtual_hearing.hearing.scheduled_for
    end_time = start_time + 30.minutes

    tzid = virtual_hearing.hearing.regional_office_timezone

    cal.add_timezone(TZInfo::Timezone.get(tzid).ical_timezone(start_time))

    cal.event do |event|
      event.dtstart = Icalendar::Values::DateTime.new(start_time, tzid: tzid)
      event.dtend = Icalendar::Values::DateTime.new(end_time, tzid: tzid)
      event.summary = "Virtual Hearing Summary"
      event.description = "Virtual Hearing Description"
      event.url = link
    end

    cal
  end

  def cancellation_calendar_invite

  end

  private


  def confirmation_subject
    case recipient.title
    when RECIPIENT_TITLES[:veteran], RECIPIENT_TITLES[:representative]
      "Confirmation: Your virtual hearing with the Board of Veterans' Appeals"
    when RECIPIENT_TITLES[:judge]
      "Confirmation: Your virtual hearing"
    end
  end

  def link
    (recipient.title == RECIPIENT_TITLES[:judge]) ? virtual_hearing.host_link : virtual_hearing.guest_link
  end
end
