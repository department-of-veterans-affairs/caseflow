# frozen_string_literal: true

class Hearings::SendSentStatusEmail
  def initialize(sent_hearing_admin_email_event:)
    @sent_hearing_admin_email_event = sent_hearing_admin_email_event
    @sent_hearing_email_event = sent_hearing_admin_email_event.sent_hearing_email_event
  end

  def call
    if email_should_send
      message = send_email
      return if message.nil?

      external_message_id = get_external_message_id(message)
      @sent_hearing_admin_email_event.update(external_message_id: external_message_id)
      log("sent admin email")
    end
  end

  private

  # Once you reach this, the email should be ready to send. If you need to block
  # emails from sending, add the conditionals to email_should_send or a sub method
  #
  # See app/jobs/hearings/send_email.rb::send_email for notes on deliver_now!
  def send_email
    email = HearingEmailStatusMailer.notification(
      sent_hearing_email_event: @sent_hearing_email_event
    )
    message = email.deliver_now!
    message
  rescue StandardError, Savon::Error, BGS::ShareError => error
    Raven.capture_exception(error)

    log("failure to send email")
    nil
  end

  # Use nocov to ignore for code coverage calculations, this code isn't tested
  # because it depends on the response from GovDelivery
  # :nocov:
  def get_external_message_id(message)
    if message.is_a?(GovDelivery::TMS::EmailMessage)
      response = message.response
      response_external_url = response.body.dig("_links", "self")
      response_external_url
    end
  end
  # :nocov:

  # Each of the guards in here should
  # - Check a condition
  # - If that condition fails, use the log function to record
  def email_should_send
    return false if email_missing?

    true
  end

  def email_missing?
    if @sent_hearing_email_event.email_address.blank?
      log("email missing")
      return true
    end

    false
  end

  def log(message)
    log_to_datadog(message)
    log_to_logger(message)
  end

  def log_to_datadog(message)
    hearing = @sent_hearing_email_event.hearing
    DataDogService.increment_counter(
      app_name: Constants.DATADOG_METRICS.HEARINGS.APP_NAME,
      metric_group: Constants.DATADOG_METRICS.HEARINGS.STATUS_EMAILS_GROUP_NAME,
      metric_name: "emails.admin_emails",
      attrs: {
        message: message,
        sent_hearing_email_event_id: @sent_hearing_email_event.id,
        sent_hearing_admin_email_event: @sent_hearing_admin_email_event.id,
        hearing_id: hearing.id,
        request_type: hearing.hearing_request_type,
        hearing_type: hearing.class.name
      }
    )
  end

  def log_to_logger(message)
    Rails.logger.info("#{message} on sent_hearing_admin_email_event_id: #{@sent_hearing_admin_email_event}," \
                      " while attempting to send admin email")
  end
end
