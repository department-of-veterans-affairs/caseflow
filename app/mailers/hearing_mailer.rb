# frozen_string_literal: true

class HearingMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsHearings@messages.va.gov>"
  layout "hearing_mailer"
  helper VirtualHearings::LinkHelper
  helper Hearings::AppellantLocationHelper
  helper Hearings::AppellantNameHelper
  helper Hearings::CalendarTemplateHelper

  def cancellation(email_recipient:, virtual_hearing: nil)
    # Guard to prevent cancellation emails from sending to the judge
    return if email_recipient.title == HearingEmailRecipient::RECIPIENT_TITLES[:judge]

    @recipient = email_recipient
    @virtual_hearing = virtual_hearing
    @hearing = virtual_hearing&.hearing

    attachments[calendar_invite_name] = cancellation_calendar_invite

    mail(
      to: recipient.email,
      subject: cancellation_subject
    )
  end

  def confirmation(email_recipient:, virtual_hearing: nil)
    @recipient = email_recipient
    @virtual_hearing = virtual_hearing
    @hearing = virtual_hearing.hearing
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

  def reminder(email_recipient:, virtual_hearing: nil, hearing: nil)
    # Guard to prevent reminder emails from sending to the judge
    return if email_recipient.title == HearingEmailRecipient::RECIPIENT_TITLES[:judge]

    @recipient = email_recipient
    @virtual_hearing = virtual_hearing
    @test_link = virtual_hearing&.test_link(email_recipient.title)
    @link = virtual_hearing.present? ? link : nil
    @hearing = hearing || virtual_hearing.hearing
    @representative_reminder =
      virtual_hearing.nil? && email_recipient.title == HearingEmailRecipient::RECIPIENT_TITLES[:representative]

    mail(
      to: recipient.email,
      subject: reminder_subject
    )
  end

  private

  attr_reader :recipient, :virtual_hearing

  def cancellation_subject
    # :reek:RepeatedConditionals
    case recipient.title
    when HearingEmailRecipient::RECIPIENT_TITLES[:appellant]
      "Your Board hearing will be held at #{@hearing.hearing_location_or_regional_office.name}"
    when HearingEmailRecipient::RECIPIENT_TITLES[:representative]
      "#{appellant_name}’s hearing will be held at #{@hearing.hearing_location_or_regional_office.name}"
    end
  end

  def confirmation_calendar_invite
    Hearings::CalendarService.confirmation_calendar_invite(virtual_hearing, recipient, link)
  end

  def cancellation_calendar_invite
    Hearings::CalendarService.update_to_video_calendar_invite(virtual_hearing, recipient)
  end

  def calendar_invite_name
    case recipient.title
    when HearingEmailRecipient::RECIPIENT_TITLES[:appellant],
      HearingEmailRecipient::RECIPIENT_TITLES[:representative]
      "BoardHearing.ics"
    when HearingEmailRecipient::RECIPIENT_TITLES[:judge]
      "Hearing.ics"
    end
  end

  def formatted_time
    # Mon, Oct 19 at 10:30am CDT
    time_format = "%a, %b %-d at %-l:%M%P %Z"
    @hearing.time.appellant_time.strftime(time_format)
  end

  def appellant_name
    @hearing.appeal.appellant_or_veteran_name
  end

  def reminder_subject
    if recipient.title == HearingEmailRecipient::RECIPIENT_TITLES[:representative]
      "Reminder: #{appellant_name}'s Board hearing is #{formatted_time} – Do Not Reply"
    else
      "Reminder: Your Board hearing is #{formatted_time} – Do Not Reply"
    end
  end

  def confirmation_subject
    # :reek:RepeatedConditionals
    case recipient.title
    when HearingEmailRecipient::RECIPIENT_TITLES[:appellant]
      "Your Board hearing has been scheduled – Do Not Reply"
    when HearingEmailRecipient::RECIPIENT_TITLES[:representative]
      "Confirmation: #{appellant_name}'s Board hearing is #{formatted_time} – Do Not Reply"
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
