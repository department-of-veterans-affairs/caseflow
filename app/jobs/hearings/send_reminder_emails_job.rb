# frozen_string_literal: true

class Hearings::SendReminderEmailsJob < ApplicationJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority
  application_attr :hearing_schedule

  def perform
    ensure_current_user_is_set

    HearingRepository.maybe_ready_for_reminder_email.each do |hearing|
      begin
        send_reminder_emails(hearing)
      rescue StandardError => error # rescue any error and allow job to continue
        capture_exception(error: error)
      end
    end
  end

  private

  def send_reminder_emails(hearing)
    appellant_reminder_type = appellant_reminder_type(hearing)
    if appellant_reminder_type.present?
      Hearings::SendEmail
        .new(
          hearing: hearing,
          type: :reminder,
          reminder_info: {
            recipient: HearingEmailRecipient::RECIPIENT_TITLES[:appellant],
            day_type: appellant_reminder_type
          }
        )
        .call
    end

    representative_reminder_type = representative_reminder_type(hearing)
    if representative_reminder_type.present?
      Hearings::SendEmail
        .new(
          hearing: hearing,
          type: :reminder,
          reminder_info: {
            recipient: HearingEmailRecipient::RECIPIENT_TITLES[:representative],
            day_type: representative_reminder_type
          }
        )
        .call
    end
  end

  def hearing_created_at(hearing)
    hearing.virtual? ? hearing.virtual_hearing.created_at : hearing.created_at
  end

  def appellant_reminder_type(hearing)
    return if hearing.appellant_recipient.email_address.blank?

    reminder_type = Hearings::ReminderService
      .new(
        hearing: hearing,
        last_sent_reminder: hearing.appellant_recipient&.reminder_sent_at,
        hearing_created_at: hearing_created_at(hearing)
      ).reminder_type

    return if reminder_type.blank?

    reminder_type
  end

  def representative_reminder_type(hearing)
    return if hearing.representative_recipient.email_address.blank?

    reminder_type = Hearings::ReminderService
      .new(
        hearing: hearing,
        last_sent_reminder: hearing.representative_recipient&.reminder_sent_at,
        hearing_created_at: hearing_created_at(hearing)
      ).reminder_type

    return if reminder_type.blank?
    # we should not send 60 day reminder email to representative
    return if reminder_type == Hearings::ReminderService::SIXTY_DAY_REMINDER

    reminder_type
  end
end
