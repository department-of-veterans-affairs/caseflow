# frozen_string_literal: true

class SlackService
  DEFAULT_CHANNEL = "#appeals-app-alerts"

  def initialize(msg:, title: "", channel: DEFAULT_CHANNEL, http_service: HTTPClient.new)
    @msg = msg
    @title = title
    @channel = channel
    @http_service = http_service
  end

  def send_notification
    return if aws_env == "uat" || url.blank?

    slack_msg = format_slack_msg

    params = { body: slack_msg.to_json, headers: { "Content-Type" => "application/json" } }
    http_service.post(url, params)
  end

  private

  attr_reader :msg, :title, :channel, :http_service

  def url
    ENV["SLACK_DISPATCH_ALERT_URL"]
  end

  def format_slack_msg
    new_channel_string = channel.dup
    new_channel_string.prepend("#") unless channel.start_with?("#")

    {
      username: "Caseflow (#{aws_env})",
      channel: new_channel_string,
      attachments: [
        {
          title: title,
          color: "#ccc",
          text: msg
        }
      ]
    }
  end

  def aws_env
    ENV.fetch("DEPLOY_ENV", "development")
  end
end
