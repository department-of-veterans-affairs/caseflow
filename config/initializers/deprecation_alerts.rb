require "#{Rails.root}/app/services/slack_service"

if Rails.env.production?
  ActiveSupport::Deprecation.behavior = ->(message, callstack) do
    # Log the deprecation warning to Rails logger
    Rails.logger.warn(message)

    # Log the deprecation warning to Sentry
    Raven.capture_message(
      'Rails Deprecation Warning in Production',
      level: 'warning',
      extra: {
        message: message,
        callstack: callstack,
        environment: Rails.env
      }
    )

    # Send the deprecation warning to the Slack channel
    slack_msg = "Deprecation Warning: #{message}"
    SlackService.new(url: ENV['SLACK_DISPATCH_ALERT_URL']).send_notification(slack_msg, "Deprecation Warning", "#appeals-deprecation-alerts")

    ActiveSupport::Deprecation::DEFAULT_BEHAVIORS[:stderr].call(message, callstack)
  end
end
