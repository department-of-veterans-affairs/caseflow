# frozen_string_literal: true

class VirtualHearingMailer < ActionMailer::Base
  default from: "solutions@public.govdelivery.com"
  layout "virtual_hearing_mailer"
  helper VirtualHearings::ExternalLinkHelper
  helper VirtualHearings::VeteranNameHelper

  def cancellation(mail_recipient:, virtual_hearing: nil)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing

    attachments[calendar_invite_name] = cancellation_calendar_invite

    mail(to: recipient.email, subject: "Your Board hearing location has changed")
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

    attachments[calendar_invite_name] = confirmation_calendar_invite

    mail(
      to: recipient.email,
      subject: "Your Board hearing time has changed"
    )
  end

  private

  attr_reader :recipient, :virtual_hearing

  def confirmation_calendar_invite
    VirtualHearings::CalendarService.confirmation_calendar_invite(virtual_hearing, recipient, link)
  end

  def cancellation_calendar_invite
    VirtualHearings::CalendarService.update_to_video_calendar_invite(virtual_hearing.hearing, recipient)
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
      "Your Board hearing has been scheduled"
    when MailRecipient::RECIPIENT_TITLES[:judge]
      hearing_date = virtual_hearing.hearing.scheduled_for.to_formatted_s(:short_date)

      "Confirmation: Your virtual hearing on #{hearing_date}"
    end
  end

  def link
    return virtual_hearing.host_link if recipient.title == MailRecipient::RECIPIENT_TITLES[:judge]

    virtual_hearing.guest_link
  end
end
