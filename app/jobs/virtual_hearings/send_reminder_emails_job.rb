# frozen_string_literal: true

class VirtualHearings::SendReminderEmailsJob < ApplicationJob
  def perform
    VirtualHearingRepository.maybe_ready_for_reminder_email.each do |virtual_hearing|
      send_reminder_email(virtual_hearing)
    end
  end

  private

  def send_reminder_email(virtual_hearing)
    days_until_hearing = days_until_hearing(virtual_hearing)
    days_from_hearing_day_to_last_sent_reminder = days_from_hearing_day_to_last_sent_reminder(virtual_hearing)
    hearing_on_monday = virtual_hearing.hearing.scheduled_for.monday?

    send_reminder = (
      # Send 2-day reminder
      (days_until_hearing <= 2 && days_from_hearing_day_to_last_sent_reminder > 2) ||
      # Send 3-day reminder (on Friday) if the hearing is on Monday
      (days_until_hearing <= 3 && hearing_on_monday) ||
      # Send 7-day reminder
      (days_until_hearing <= 7 && days_from_hearing_day_to_last_sent_reminder > 7)
    )

    # Guard to prevent sending emails if the date of the hearing is already passed (the query)
    # should prevent this) or we shouldn't send an email because we already sent one recently.
    return if days_until_hearing < 0 || !send_reminder

    VirtualHearings::SendEmail.new(virtual_hearing: virtual_hearing, type: :reminder).call
  end

  def days_until_hearing(virtual_hearing)
    (virtual_hearing.hearing.scheduled_for - Time.zone.now.utc) / 1.day
  end

  def days_from_hearing_day_to_last_sent_reminder(virtual_hearing)
    # Pick arbitrarily big value if the reminder has never been sent.
    return 9999 if virtual_hearing.try(:date_reminder_sent).nil?

    (virtual_hearing.hearing.scheduled_for - virtual_hearing.try(:date_reminder_sent)) / 1.day
  end
end
