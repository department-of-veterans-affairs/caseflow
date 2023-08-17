# frozen_string_literal: true

# @note For use with `ActiveSupport::Deprecation.behavior=`.
module DeprecationWarnings
  class ProductionHandler < BaseHandler
    APP_NAME = "caseflow"
    SLACK_ALERT_CHANNEL = "#appeals-deprecation-alerts"

    class << self
      def call(message, callstack, deprecation_horizon, gem_name)
        emit_warning_to_application_logs(message)
        emit_warning_to_sentry(message, callstack, deprecation_horizon, gem_name)
        emit_warning_to_slack_alerts_channel(message)
      rescue StandardError => error
        Raven.capture_exception(error)
      end

      private

      def emit_warning_to_application_logs(message)
        Rails.logger.warn(message)
      end

      def emit_warning_to_sentry(message, callstack, deprecation_horizon, gem_name)
        # Pre-emptive bugfix for future versions of the `sentry-raven` gem:
        #   Need to convert callstack elements from `Thread::Backtrace::Location` objects to `Strings`
        #   to avoid a `TypeError` on `options.deep_dup` in `Raven.capture_message`:
        #   https://github.com/getsentry/sentry-ruby/blob/2e07e0295ba83df4c76c7bf3315d199c7050a7f9/lib/raven/instance.rb#L114
        callstack_strings = callstack.map(&:to_s)

        Raven.capture_message(
          message,
          level: "warning",
          extra: {
            message: message,
            gem_name: gem_name,
            deprecation_horizon: deprecation_horizon,
            callstack: callstack_strings,
            environment: Rails.env
          }
        )
      end

      def emit_warning_to_slack_alerts_channel(message)
        slack_alert_title = "Deprecation Warning - #{APP_NAME} (#{ENV['DEPLOY_ENV']})"

        SlackService
          .new(url: ENV["SLACK_DISPATCH_ALERT_URL"])
          .send_notification(message, slack_alert_title, SLACK_ALERT_CHANNEL)
      end
    end
  end
end
