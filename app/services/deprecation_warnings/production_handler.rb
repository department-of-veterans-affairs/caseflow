# frozen_string_literal: true

# @note For use with `ActiveSupport::Deprecation.behavior=` or `Rails.application.config.active_support.deprecation=`
module DeprecationWarnings
  class ProductionHandler
    APP_NAME = "caseflow"
    SLACK_ALERT_TITLE = "Deprecation Warning - #{APP_NAME} (#{ENV['DEPLOY_ENV']})"
    SLACK_ALERT_CHANNEL = "#appeals-deprecation-alerts"

    class << self
      # Adhere to `.call` signature expected by `ActiveSupport::Deprecation.behavior=`.
      #   https://github.com/rails/rails/blob/a4581b53aae93a8dd3205abae0630398cbce9204/activesupport/lib/active_support/deprecation/behaviors.rb#L70-L71
      # :reek:LongParameterList
      def call(message, callstack, deprecation_horizon, gem_name)
        emit_warning_to_sentry(message, callstack, deprecation_horizon, gem_name)
        emit_warning_to_slack_alerts_channel(message)
      rescue StandardError => error
        Raven.capture_exception(error)
      end

      # Must respond to `.arity` to play nice with `ActiveSupport::Deprecation.behavior=`
      #   and return number of arguments accepted by `.call`.
      #   https://github.com/rails/rails/blob/a4581b53aae93a8dd3205abae0630398cbce9204/activesupport/lib/active_support/deprecation/behaviors.rb#L101
      def arity
        method(:call).arity
      end

      private

      # :reek:LongParameterList
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
        SlackService.new.send_notification(message, SLACK_ALERT_TITLE, SLACK_ALERT_CHANNEL)
      end
    end
  end
end
