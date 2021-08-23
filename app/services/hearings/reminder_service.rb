# frozen_string_literal: true

##
# Service that determines whether or not a send a reminder to the appellant or representative
# about their hearing.

class Hearings::ReminderService
  TWO_DAY_REMINDER = :two_day_reminder
  THREE_DAY_REMINDER = :three_day_reminder
  SEVEN_DAY_REMINDER = :seven_day_reminder
  SIXTY_DAY_REMINDER = :sixty_day_reminder

  def initialize(hearing:, last_sent_reminder:, hearing_created_at:)
    @hearing = hearing
    @last_sent_reminder = last_sent_reminder
    @hearing_created_at = hearing_created_at
  end

  # returns nil if no reminder email should be sent
  def reminder_type
    return if days_until_hearing <= 0

    type_of_reminder = which_type_of_reminder_to_send
    # Only log 60 day reminder type email but do not send
    return if type_of_reminder == SIXTY_DAY_REMINDER

    # This stops reminder emails from going out for any video/central hearings until
    # we to enable that. Because it still calls 'which_type_of_reminder_to_send'
    # we will log the email to be sent.
    #
    # Because hearing.virtual? will return false for any 'cancelled' virtual
    # hearings, this prevents reminder emails for cancelled virtual hearings.
    return type_of_reminder if hearing.virtual?
  end

  private

  attr_reader :hearing
  attr_reader :last_sent_reminder

  def log_reminder_type(type)
    Rails.logger.info(
      "Send #{type} reminder emails: ( "\
      "Last sent reminder: #{last_sent_reminder}, " \
      "Days until hearing: #{days_until_hearing}, " \
      "Days from hearing day to last reminder sent: #{days_from_hearing_day_to_last_sent_reminder}, " \
      "Days between hearing and created at: #{days_between_hearing_and_created_at}, " \
      "Is hearing scheduled for Monday?: #{hearing.scheduled_for.monday?}, " \
      "Is it a virtual_hearing?: #{hearing.virtual?}, " \
      "Hearing class and id: #{hearing.class.name}, #{hearing.id})"
    )
    send_to_datadog(type)
  end

  # Remove this when we enable feature to allow reminder for all hearings
  def send_to_datadog(type)
    DataDogService.increment_counter(
      app_name: Constants.DATADOG_METRICS.HEARINGS.APP_NAME,
      metric_group: Constants.DATADOG_METRICS.HEARINGS.REMINDER_EMAILS_GROUP_NAME,
      metric_name: "emails.would_be_sent",
      attrs: {
        reminder_type: type,
        hearing_id: hearing.id,
        request_type: hearing.hearing_request_type,
        hearing_type: hearing.class.name
      }
    )
  end

  def which_type_of_reminder_to_send
    if should_send_2_day_reminder?
      log_reminder_type("2 day")
      TWO_DAY_REMINDER
    elsif should_send_3_day_friday_reminder?
      log_reminder_type("3 day")
      THREE_DAY_REMINDER
    elsif should_send_7_day_reminder?
      log_reminder_type("7 day")
      SEVEN_DAY_REMINDER
    elsif should_send_60_day_reminder?
      log_reminder_type("60 day")
      SIXTY_DAY_REMINDER
    end
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

  def should_send_60_day_reminder?
    days_between_hearing_and_created_at > 60 &&
      days_until_hearing <= 60 && days_from_hearing_day_to_last_sent_reminder > 60
  end

  # Determines the date between when the hearing is scheduled, and when the virtual hearing was scheduled.
  # If the virtual hearing was scheduled within a reminder period, we skip sending the reminder for that period
  # because the confirmation will have redundant information.
  def days_between_hearing_and_created_at
    (hearing.scheduled_for - @hearing_created_at) / 1.day
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
