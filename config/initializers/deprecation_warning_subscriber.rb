# frozen_string_literal: true

# @note For use in conjuction with setting `Rails.application.config.active_support.deprecation = :notify`.
#   Whenever a “deprecation.rails” notification is published, it will dispatch the event
#   (ActiveSupport::Notifications::Event) to method #deprecation.
class DeprecationWarningSubscriber < ActiveSupport::Subscriber
  SLACK_ALERT_TITLE = "Deprecation Warning"
  SLACK_ALERT_CHANNEL = "#appeals-deprecation-alerts"

  attach_to :rails

  def deprecation(event)
    emit_warning_to_application_logs(event)
    emit_warning_to_sentry(event)
    emit_warning_to_slack_alerts_channel(event)
  end

  private

  def emit_warning_to_application_logs(event)
    Rails.logger.warn(event.payload[:message])
  end

  def emit_warning_to_sentry(event)
    Raven.capture_message(
      event.payload[:message],
      level: "warning",
      extra: {
        message: event.payload[:message],
        callstack: event.payload[:callstack],
        environment: Rails.env
      }
    )
  end

  def emit_warning_to_slack_alerts_channel(event)
    SlackService
      .new(url: ENV["SLACK_DISPATCH_ALERT_URL"])
      .send_notification(event.payload[:message], SLACK_ALERT_TITLE, SLACK_ALERT_CHANNEL)
  end
end
