# frozen_string_literal: true

class Hearings::SendSentStatusEmail
  class RecipientIsDeceasedVeteran < StandardError; end

  def initialize(sent_hearing_email_event:)
    @sent_hearing_email_event = sent_hearing_email_event
  end

  def call
    send_email if email_should_send
  end

  private

  # Once you reach this, the email should be ready to send. If you need to block
  # emails from sending, add the conditionals to email_should_send or a sub method
  #
  # See app/jobs/hearings/send_email.rb::send_email for notes on deliver_now!
  def send_email
    email = HearingEmailStatusMailer.notification(
      sent_hearing_email_event: sent_hearing_email_event
    )
    email.deliver_now!
  end

  # Each of the guards in here should
  # - Check a condition
  # - If that condition fails, use the log function to record
  def email_should_send
    return false if invalid_email?

    true
  end

  def invalid_email?
    if sent_hearing_email_event.email_address.blank?
      log("email_invalid")
      return true
    end

    false
  end

  def log(failure)
    log_to_datadog(failure)
    log_to_logger(failure)
  end

  def log_to_datadog(failure)
    DataDogService.increment_counter(
      app_name: Constants.DATADOG_METRICS.HEARINGS.APP_NAME,
      metric_group: Constants.DATADOG_METRICS.HEARINGS.STATUS_EMAILS_GROUP_NAME,
      metric_name: "emails.failed",
      attrs: { failure: failure }
    )
  end

  def log_to_logger(failure)
    Rails.logger.info("#{failure}: Failed to SendSentStatusEmail")
  end
end
