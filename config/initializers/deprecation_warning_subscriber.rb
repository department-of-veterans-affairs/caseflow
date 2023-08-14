# frozen_string_literal: true

# @note For use in conjuction with setting `Rails.application.config.active_support.deprecation = :notify`.
#   Whenever a “deprecation.rails” notification is published, it will dispatch the event
#   (ActiveSupport::Notifications::Event) to method #deprecation.
class DeprecationWarningSubscriber < ActiveSupport::Subscriber
  APP_NAME = "caseflow"
  SLACK_ALERT_CHANNEL = "#appeals-deprecation-alerts"

  attach_to :rails

  def deprecation(event)
    emit_warning_to_application_logs(event)
    emit_warning_to_sentry(event)
    emit_warning_to_slack_alerts_channel(event)
  rescue StandardError => error
    Raven.capture_exception(error)
  end

  private

  def emit_warning_to_application_logs(event)
    Rails.logger.warn(event.payload[:message])
  end

  def emit_warning_to_sentry(event)
    # Pre-emptive bugfix for future versions of the `sentry-raven` gem:
    #   Need to convert callstack elements from `Thread::Backtrace::Location` objects to `Strings`
    #   to avoid a `TypeError` on `options.deep_dup` in `Raven.capture_message`:
    #   https://github.com/getsentry/sentry-ruby/blob/2e07e0295ba83df4c76c7bf3315d199c7050a7f9/lib/raven/instance.rb#L114
    callstack_strings = event.payload[:callstack].map(&:to_s)

    Raven.capture_message(
      event.payload[:message],
      level: "warning",
      extra: {
        message: event.payload[:message],
        gem_name: event.payload[:gem_name],
        deprecation_horizon: event.payload[:deprecation_horizon],
        callstack: callstack_strings,
        environment: Rails.env
      }
    )
  end

  def emit_warning_to_slack_alerts_channel(event)
    slack_alert_title = "Deprecation Warning - #{APP_NAME} (#{ENV['DEPLOY_ENV']})"

    SlackService
      .new(url: ENV["SLACK_DISPATCH_ALERT_URL"])
      .send_notification(event.payload[:message], slack_alert_title, SLACK_ALERT_CHANNEL)
  end

  def raise_if_fixed_deprecation_triggered(event)
    # Checking for deprecated message in development and test environments
    if Rails.env.development? || Rails.env.test?
      if event.payload[:message].include?("The success? predicate is deprecated")
        message = "Fixed deprecation warning triggered: #{event.payload[:message]}"
        raise DeprecationWarning, message
      end
    end
  end
end
