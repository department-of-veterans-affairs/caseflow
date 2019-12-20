# frozen_string_literal: true

class VirtualHearingMailer < ActionMailer::Base
  default from: "solutions@public.govdelivery.com"
  layout "virtual_hearing_mailer"
  attr_reader :recipient, :virtual_hearing

  def cancellation(mail_recipient:, virtual_hearing: nil)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing

    mail(to: recipient.email, subject: "Updated location: Your hearing with the Board of Veterans' Appeals")
  end

  def confirmation(mail_recipient:, virtual_hearing: nil)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing
    @link = link

    attachments[calendar_invite_name] = confirmation_calendar_invite

    mail(to: recipient.email, subject: confirmation_subject)
  end

  def updated_time_confirmation(mail_recipient:, virtual_hearing: nil)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing
    @link = link

    attachments[calendar_invite_name]

    mail(
      to: recipient.email,
      subject: "Updated time: Your virtual hearing with the Board of Veterans' Appeals"
    )
  end

  def calendar_invite(mail_recipient:, virtual_hearing:)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing
    @link = link

    confirmation_calendar_invite
  end

  private

  def confirmation_calendar_invite
    VirtualHearings::CalendarService.confirmation_calendar_invite(virtual_hearing, recipient, link)
  end

  def calendar_invite_name
    case recipient.title
    when MailRecipient::RECIPIENT_TITLES[:veteran], MailRecipient::RECIPIENT_TITLES[:representative]
      "BoardHearing.ics"
    when MailRecipient::RECIPIENT_TITLES[:judge]
      "VirtualHearing.ics"
    end
  end

  def confirmation_subject
    case recipient.title
    when MailRecipient::RECIPIENT_TITLES[:veteran], MailRecipient::RECIPIENT_TITLES[:representative]
      "Confirmation: Your virtual hearing with the Board of Veterans' Appeals"
    when MailRecipient::RECIPIENT_TITLES[:judge]
      "Confirmation: Your virtual hearing"
    end
  end

  def link
    return virtual_hearing.host_link if recipient.title == MailRecipient::RECIPIENT_TITLES[:judge]
    virtual_hearing.guest_link
  end
end
