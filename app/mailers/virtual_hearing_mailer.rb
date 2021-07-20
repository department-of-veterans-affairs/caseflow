# frozen_string_literal: true

class VirtualHearingMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsHearings@messages.va.gov>"
  layout "virtual_hearing_mailer"
  helper VirtualHearings::LinkHelper
  helper VirtualHearings::AppellantLocationHelper
  helper VirtualHearings::AppellantNameHelper
  helper VirtualHearings::CalendarTemplateHelper

  def cancellation(email_recipient:, virtual_hearing: nil)
    # Guard to prevent cancellation emails from sending to the judge
    return if email_recipient.title == HearingEmailRecipient::RECIPIENT_TITLES[:judge]

    @recipient = email_recipient
    @virtual_hearing = virtual_hearing

    attachments[calendar_invite_name] = cancellation_calendar_invite

    mail(
      to: recipient.email,
      subject: "Your Board hearing location has changed – Do Not Reply"
    )
  end

  def confirmation(email_recipient:, virtual_hearing: nil)
    @recipient = email_recipient
    @virtual_hearing = virtual_hearing
    @link = link
    @test_link = virtual_hearing&.test_link(email_recipient.title)

    attachments[calendar_invite_name] = confirmation_calendar_invite

    mail(to: recipient.email, subject: confirmation_subject)
  end

  def updated_time_confirmation(email_recipient:, virtual_hearing: nil)
    @recipient = email_recipient
    @virtual_hearing = virtual_hearing
    @link = link
    @test_link = virtual_hearing&.test_link(email_recipient.title)

    attachments[calendar_invite_name] = confirmation_calendar_invite

    mail(
      to: recipient.email,
      subject: "Your Board hearing time has changed – Do Not Reply"
    )
  end

  def reminder(email_recipient:, virtual_hearing: nil)
    # Guard to prevent reminder emails from sending to the judge
    return if email_recipient.title == HearingEmailRecipient::RECIPIENT_TITLES[:judge]

    @recipient = email_recipient
    @virtual_hearing = virtual_hearing
    @link = link
    @test_link = virtual_hearing&.test_link(email_recipient.title)

    # Mon, Oct 19 at 10:30am CDT
    time_format = "%a, %b %-d at %-l:%M%P %Z"
    formatted_time = virtual_hearing.hearing.time.appellant_time.strftime(time_format)

    mail(
      to: recipient.email,
      subject: "Reminder: Your Board hearing is #{formatted_time} – Do Not Reply"
    )
  end

  private

  attr_reader :recipient, :virtual_hearing

  def confirmation_calendar_invite
    VirtualHearings::CalendarService.confirmation_calendar_invite(virtual_hearing, recipient, link)
  end

  def cancellation_calendar_invite
    VirtualHearings::CalendarService.update_to_video_calendar_invite(virtual_hearing, recipient)
  end

  def calendar_invite_name
    case recipient.title
    when HearingEmailRecipient::RECIPIENT_TITLES[:appellant],
      HearingEmailRecipient::RECIPIENT_TITLES[:representative]
      "BoardHearing.ics"
    when HearingEmailRecipient::RECIPIENT_TITLES[:judge]
      "VirtualHearing.ics"
    end
  end

  def confirmation_subject
    case recipient.title
    when HearingEmailRecipient::RECIPIENT_TITLES[:appellant],
      HearingEmailRecipient::RECIPIENT_TITLES[:representative]
      "Your Board hearing has been scheduled – Do Not Reply"
    when HearingEmailRecipient::RECIPIENT_TITLES[:judge]
      hearing_date = virtual_hearing.hearing.scheduled_for.to_formatted_s(:short_date)

      "Confirmation: Your virtual hearing on #{hearing_date} – Do Not Reply"
    end
  end

  def link
    return virtual_hearing.host_link if recipient.title == HearingEmailRecipient::RECIPIENT_TITLES[:judge]

    virtual_hearing.guest_link
  end
end
