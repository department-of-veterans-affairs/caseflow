# frozen_string_literal: true

##
# Service that determines whether or not a send a reminder to the appellant or representative
# about their hearing.

class Hearings::ReminderService
  def initialize(hearing, last_sent_reminder, created_at)
    @hearing = hearing
    @last_sent_reminder = last_sent_reminder
    @created_at = created_at
  end

  def should_send_reminder_email?
    return false if days_until_hearing <= 0

    # TODO: This stops emails from going out for any video/central hearings until
    # we want them to, it allows the logging to happen though.
    # which_type_of_reminder_to_send && hearing.virtual?
    which_type_of_reminder_to_send
  end

  private

  attr_reader :hearing
  attr_reader :last_sent_reminder

  def log_reminder_type(type)
    Rails.logger.info(
      "Send #{type} reminder emails: ( "\
      "Last sent reminder: #{last_sent_reminder}, \n " \
      "Days until hearing: #{days_until_hearing}, \n" \
      "Days from hearing day to last reminder sent: #{days_from_hearing_day_to_last_sent_reminder}, \n" \
      "Days between hearing and created at: #{days_between_hearing_and_created_at}, \n" \
      "Is hearing scheduled for Monday?: #{hearing.scheduled_for.monday?})"
    )
  end

  def which_type_of_reminder_to_send
    if should_send_2_day_reminder?
      log_reminder_type("2 day")
    elsif should_send_3_day_friday_reminder?
      log_reminder_type("3 day")
    elsif should_send_7_day_reminder?
      log_reminder_type("7 day")
    else
      return false
    end

    true
  end

  def should_send_2_day_reminder?
    days_between_hearing_and_created_at > 2 &&
      days_until_hearing <= 2 && days_from_hearing_day_to_last_sent_reminder > 2
  end

  # The 3 day reminder is a special reminder that is sent on Friday, *only* if the hearing
  # itself is on Monday.
  def should_send_3_day_friday_reminder?
    Time.zone.now.utc.friday? &&
      days_between_hearing_and_created_at > 3 && days_until_hearing <= 3 &&
      hearing.scheduled_for.monday? && days_from_hearing_day_to_last_sent_reminder > 3
  end

  def should_send_7_day_reminder?
    days_between_hearing_and_created_at > 7 &&
      days_until_hearing <= 7 && days_from_hearing_day_to_last_sent_reminder > 7
  end

  # Determines the date between when the hearing is scheduled, and when the virtual hearing was scheduled.
  # If the virtual hearing was scheduled within a reminder period, we skip sending the reminder for that period
  # because the confirmation will have redundant information.
  def days_between_hearing_and_created_at
    (hearing.scheduled_for - @created_at) / 1.day
  end

  def days_until_hearing
    (hearing.scheduled_for - Time.zone.now.utc) / 1.day
  end

  def days_from_hearing_day_to_last_sent_reminder
    # Pick arbitrarily big value if the reminder has never been sent.
    return Float::INFINITY if last_sent_reminder.nil?

    (hearing.scheduled_for - last_sent_reminder) / 1.day
  end
end
