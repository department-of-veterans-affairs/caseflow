# frozen_string_literal: true

##
# Service that determines whether or not a send a reminder to the appellant or representative
# about their virtual hearing.

class VirtualHearings::ReminderService
  def initialize(virtual_hearing, last_sent_reminder)
    @virtual_hearing = virtual_hearing
    @last_sent_reminder = last_sent_reminder
  end

  def should_send_reminder_email?
    return false if days_until_hearing <= 0

    should_send_2_day_reminder? ||
      should_send_3_day_friday_reminder? ||
      should_send_7_day_reminder?
  end

  private

  attr_reader :virtual_hearing
  attr_reader :last_sent_reminder

  def should_send_2_day_reminder?
    days_between_hearing_and_created_at > 2 &&
      days_until_hearing <= 2 && days_from_hearing_day_to_last_sent_reminder > 2
  end

  # The 3 day reminder is a special reminder that is sent on Friday, *only* if the hearing
  # itself is on Monday.
  def should_send_3_day_friday_reminder?
    Time.zone.now.utc.friday? &&
      days_between_hearing_and_created_at > 3 && days_until_hearing <= 3 &&
      virtual_hearing.hearing.scheduled_for.monday? && days_from_hearing_day_to_last_sent_reminder > 3
  end

  def should_send_7_day_reminder?
    days_between_hearing_and_created_at > 7 &&
      days_until_hearing <= 7 && days_from_hearing_day_to_last_sent_reminder > 7
  end

  # Determines the date between when the hearing is scheduled, and when the virtual hearing was scheduled.
  # If the virtual hearing was scheduled within a reminder period, we skip sending the reminder for that period
  # because the confirmation will have redundant information.
  def days_between_hearing_and_created_at
    (virtual_hearing.hearing.scheduled_for - virtual_hearing.created_at) / 1.day
  end

  def days_until_hearing
    (virtual_hearing.hearing.scheduled_for - Time.zone.now.utc) / 1.day
  end

  def days_from_hearing_day_to_last_sent_reminder
    # Pick arbitrarily big value if the reminder has never been sent.
    return Float::INFINITY if last_sent_reminder.nil?

    (virtual_hearing.hearing.scheduled_for - last_sent_reminder) / 1.day
  end
end
