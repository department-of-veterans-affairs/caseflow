# frozen_string_literal: true

module DeprecationWarnings
  # Regular expressions for custom deprecation warnings that we have addressed in the codebase
  CUSTOM_DEPRECATION_WARNING_REGEXES = [
    /Caseflow::Migration is deprecated/
  ].freeze

  # Regular expressions for Rails 7.0 deprecation warnings that we have addressed in the codebase
  RAILS_7_0_FIXED_DEPRECATION_WARNING_REGEXES = [
    /Initialization autoloaded the constant/,
    /Calling `\[\]=` to an ActiveModel\:\:Errors is deprecated/,
    /Calling `clear` to an ActiveModel\:\:Errors message array in order to delete all errors is deprecated/,
    /Calling `delete` to an ActiveModel\:\:Errors messages hash is deprecated/,
    /Calling `<<` to an ActiveModel\:\:Errors message array in order to add an error is deprecated/,
    /ActiveModel\:\:Errors#to_xml is deprecated/,
    /ActiveModel\:\:Errors#keys is deprecated/,
    /ActiveModel\:\:Errors#values is deprecated/,
    /ActiveModel\:\:Errors#slice\! is deprecated/,
    /ActiveModel\:\:Errors#to_h is deprecated/,
    /Enumerating ActiveModel\:\:Errors as a hash has been deprecated/
  ].freeze

  # Regular expressions for deprecation warnings that should raise an exception on detection
  DISALLOWED_DEPRECATION_WARNING_REGEXES = [
    *CUSTOM_DEPRECATION_WARNING_REGEXES,
    *RAILS_7_0_FIXED_DEPRECATION_WARNING_REGEXES
  ].freeze

  # @note For use with `ActiveSupport::Deprecation.behavior=` or `Rails.application.config.active_support.deprecation=`
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
