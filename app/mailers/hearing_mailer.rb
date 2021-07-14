# frozen_string_literal: true

class HearingMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsHearings@messages.va.gov>"
  layout "hearing_mailer"
  helper VirtualHearings::LinkHelper
  helper Hearings::AppellantLocationHelper
  helper Hearings::AppellantNameHelper
  helper Hearings::CalendarTemplateHelper

  def cancellation(mail_recipient:, virtual_hearing: nil)
    # Guard to prevent cancellation emails from sending to the judge
    return if mail_recipient.title == MailRecipient::RECIPIENT_TITLES[:judge]

    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing

    attachments[calendar_invite_name] = cancellation_calendar_invite

    mail(
      to: recipient.email,
      subject: "Your Board hearing location has changed – Do Not Reply"
    )
  end

  def confirmation(mail_recipient:, virtual_hearing: nil)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing
    @link = link
    @test_link = virtual_hearing&.test_link(mail_recipient.title)

    attachments[calendar_invite_name] = confirmation_calendar_invite

    mail(to: recipient.email, subject: confirmation_subject)
  end

  def updated_time_confirmation(mail_recipient:, virtual_hearing: nil)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing
    @link = link
    @test_link = virtual_hearing&.test_link(mail_recipient.title)

    attachments[calendar_invite_name] = confirmation_calendar_invite

    mail(
      to: recipient.email,
      subject: "Your Board hearing time has changed – Do Not Reply"
    )
  end

  def reminder(mail_recipient:, virtual_hearing: nil)
    # Guard to prevent reminder emails from sending to the judge
    return if mail_recipient.title == MailRecipient::RECIPIENT_TITLES[:judge]

    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing
    @link = link
    @test_link = virtual_hearing&.test_link(mail_recipient.title)

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
    Hearings::CalendarService.confirmation_calendar_invite(virtual_hearing, recipient, link)
  end

  def cancellation_calendar_invite
    Hearings::CalendarService.update_to_video_calendar_invite(virtual_hearing, recipient)
  end

  def calendar_invite_name
    case recipient.title
    when MailRecipient::RECIPIENT_TITLES[:appellant], MailRecipient::RECIPIENT_TITLES[:representative]
      "BoardHearing.ics"
    when MailRecipient::RECIPIENT_TITLES[:judge]
      "Hearing.ics"
    end
  end

  def confirmation_subject
    case recipient.title
    when MailRecipient::RECIPIENT_TITLES[:appellant], MailRecipient::RECIPIENT_TITLES[:representative]
      "Your Board hearing has been scheduled – Do Not Reply"
    when MailRecipient::RECIPIENT_TITLES[:judge]
      hearing_date = virtual_hearing.hearing.scheduled_for.to_formatted_s(:short_date)

      "Confirmation: Your virtual hearing on #{hearing_date} – Do Not Reply"
    end
  end

  def link
    return virtual_hearing.host_link if recipient.title == MailRecipient::RECIPIENT_TITLES[:judge]

    virtual_hearing.guest_link
  end
end
