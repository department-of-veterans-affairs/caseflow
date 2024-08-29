# frozen_string_literal: true

##
# HearingMailer will:
# - Generate emails from the templates in app/views/hearing_mailer
#   - All types will use layouts/hearing_mailer.html.erb to determine the order of the sections
#     - Example section: :test_your_connection, :rescheduling_or_canceling_your_hearing
#   - The method name like "cancellation" determines which template is used.
#   - The 'cancellation' method uses app/views/hearing_mailer/cancellation.html.erb
#   - cancellation.html.erb prepends the recipient type and uses another template.
# - Generate email subjects based on the type of email.
# - Create the calendar invites that get attached to the emails.
##
# rubocop:disable Rails/ApplicationMailer
class HearingMailer < ActionMailer::Base
  default from: "Board of Veterans' Appeals <BoardofVeteransAppealsHearings@messages.va.gov>"
  layout "hearing_mailer"
  helper VirtualHearings::LinkHelper
  helper Hearings::AppellantLocationHelper
  helper Hearings::AppellantNameHelper
  helper Hearings::CalendarTemplateHelper

  class BadVirtualLinkError < StandardError; end
  BAD_VIRTUAL_LINK_TEXT = "care.va.gov"

  def cancellation(email_recipient_info:, virtual_hearing: nil)
    # Guard to prevent cancellation emails from sending to the judge
    return if judge_is_recipient?(email_recipient_info)

    @recipient_info = email_recipient_info
    @virtual_hearing = virtual_hearing
    @hearing = virtual_hearing&.hearing

    attachments[calendar_invite_name] = cancellation_calendar_invite

    mail(
      to: recipient_info.email,
      subject: cancellation_subject
    )
  end

  def confirmation(email_recipient_info:, virtual_hearing: nil, custom_subject: nil)
    @recipient_info = email_recipient_info
    @virtual_hearing = virtual_hearing
    @hearing = virtual_hearing.hearing
    @link = link
    @test_link = virtual_hearing&.test_link(email_recipient_info.title)

    attachments[calendar_invite_name] = confirmation_calendar_invite

    mail(to: recipient_info.email, subject: custom_subject || confirmation_subject)
  end

  def updated_time_confirmation(email_recipient_info:, virtual_hearing: nil)
    @recipient_info = email_recipient_info
    @virtual_hearing = virtual_hearing
    @link = link
    @test_link = virtual_hearing&.test_link(email_recipient_info.title)
    @non_appellant_updated_time = email_recipient_info.title != HearingEmailRecipient::RECIPIENT_TITLES[:appellant]
    attachments[calendar_invite_name] = confirmation_calendar_invite
    subject = if recipient_info.title == HearingEmailRecipient::RECIPIENT_TITLES[:judge]
                "Your Board hearing time has changed – Do Not Reply"
              else
                "Your Board hearing date/time has changed – Do Not Reply"
              end
    mail(
      to: recipient_info.email,
      subject: subject
    )
  end

  def reminder(email_recipient_info:, day_type:, virtual_hearing: nil, hearing: nil)
    # Guard to prevent reminder emails from sending to the judge
    return if judge_is_recipient?(email_recipient_info)

    @recipient_info = email_recipient_info
    @virtual_hearing = virtual_hearing
    @test_link = virtual_hearing&.test_link(email_recipient_info.title)
    @link = virtual_hearing.present? ? link : nil
    @hearing = hearing || virtual_hearing.hearing
    @representative_reminder =
      virtual_hearing.nil? && email_recipient_info.title == HearingEmailRecipient::RECIPIENT_TITLES[:representative]
    @reminder_type = day_type

    mail(
      to: recipient_info.email,
      subject: reminder_subject
    )
  end

  private

  attr_reader :recipient_info, :virtual_hearing

  def cancellation_subject
    # :reek:RepeatedConditionals
    case recipient_info.title
    when HearingEmailRecipient::RECIPIENT_TITLES[:appellant]
      "There has been a change to your upcoming Board Hearing – Do Not Reply"
    when HearingEmailRecipient::RECIPIENT_TITLES[:representative]
      "There has been a change to your client’s upcoming Board hearing – Do Not Reply"
    end
  end

  def confirmation_calendar_invite
    Hearings::CalendarService.confirmation_calendar_invite(virtual_hearing, recipient_info, link)
  end

  def cancellation_calendar_invite
    Hearings::CalendarService.update_to_video_calendar_invite(virtual_hearing, recipient_info)
  end

  def calendar_invite_name
    case recipient_info.title
    when HearingEmailRecipient::RECIPIENT_TITLES[:appellant],
      HearingEmailRecipient::RECIPIENT_TITLES[:representative]
      "BoardHearing.ics"
    when HearingEmailRecipient::RECIPIENT_TITLES[:judge]
      "Hearing.ics"
    end
  end

  def formatted_time(time)
    # Mon, Oct 19 at 10:30am CDT
    time_format = "%a, %b %-d at %-l:%M%P %Z"
    time.strftime(time_format)
  end

  def appellant_name
    @hearing.appeal.appellant_or_veteran_name
  end

  # Last name of appellant
  def appellant_last_name
    appellant_name.split[-1]
  end

  def reminder_subject
    if recipient_info.title == HearingEmailRecipient::RECIPIENT_TITLES[:representative]
      "Reminder: #{appellant_name}'s Board hearing is #{formatted_time(@hearing.poa_time)} – Do Not Reply"
    else
      "Reminder: Your hearing is #{formatted_time(@hearing.appellant_time)} – Do Not Reply"
    end
  end

  def confirmation_subject
    # :reek:RepeatedConditionals
    case recipient_info.title
    when HearingEmailRecipient::RECIPIENT_TITLES[:appellant]
      "Your Board hearing has been scheduled – Do Not Reply"
    when HearingEmailRecipient::RECIPIENT_TITLES[:representative]
      "Confirmation: #{appellant_last_name}'s Board hearing is #{formatted_time(@hearing.poa_time)} – Do Not Reply"
    when HearingEmailRecipient::RECIPIENT_TITLES[:judge]
      hearing_date = virtual_hearing.hearing.scheduled_for.to_formatted_s(:short_date)

      "Confirmation: Your virtual hearing on #{hearing_date} – Do Not Reply"
    end
  end

  def link
    hearing_link = if judge_is_recipient?(recipient_info)
                     virtual_hearing.host_link
                   else
                     virtual_hearing.guest_link
                   end

    # Raise an error if the link contains the old virtual hearing link 2021-11-10
    if hearing_link.nil? || hearing_link.include?(BAD_VIRTUAL_LINK_TEXT)
      fail BadVirtualLinkError, virtual_hearing_id: virtual_hearing&.id
    end

    hearing_link
  end

  def judge_is_recipient?(email_recipient_info)
    email_recipient_info.title == HearingEmailRecipient::RECIPIENT_TITLES[:judge]
  end
end
# rubocop:enable Rails/ApplicationMailer
