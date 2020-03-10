# frozen_string_literal: true

class VirtualHearingMailer < ActionMailer::Base
  default from: "BoardofVeteransAppealsHearings@public.govdelivery.com"
  layout "virtual_hearing_mailer"
  helper VirtualHearings::ExternalLinkHelper
  helper VirtualHearings::VeteranNameHelper

  def cancellation(mail_recipient:, virtual_hearing: nil)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing

    attachments[calendar_invite_name] = cancellation_calendar_invite

    mail(to: recipient.email, subject: COPY::VIRTUAL_HEARING_MAILER_CANCELLATION_SUBJECT)
  end

  def confirmation(mail_recipient:, virtual_hearing: nil)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing
    @link = link
    @test_link = test_link

    attachments[calendar_invite_name] = confirmation_calendar_invite

    mail(to: recipient.email, subject: COPY::VIRTUAL_HEARING_MAILER_CONFIRMATION_SUBJECT)
  end

  def updated_time_confirmation(mail_recipient:, virtual_hearing: nil)
    @recipient = mail_recipient
    @virtual_hearing = virtual_hearing
    @link = link
    @test_link = test_link

    attachments[calendar_invite_name] = confirmation_calendar_invite

    mail(
      to: recipient.email,
      subject: COPY::VIRTUAL_HEARING_MAILER_UPDATE_TIME_SUBJECT
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
    "BoardHearing.ics"
  end

  def link
    virtual_hearing.guest_link
  end

  def test_link
    "https://vc.va.gov/webapp2/conference/test_call?name=Veteran&join=1"
  end
end
