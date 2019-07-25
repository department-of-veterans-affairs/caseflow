# frozen_string_literal: true

class SlackService
  DEFAULT_CHANNEL = "#appeals-app-alerts"

  def initialize(url:)
    @url = url
  end

  attr_reader :url

  def send_notification(msg, title = "", channel = DEFAULT_CHANNEL)
    return unless url

    slack_msg = format_slack_msg(msg, title, channel)

    params = { body: slack_msg.to_json, headers: { "Content-Type" => "application/json" } }
    http_service.post(url, params)
  end

  private

  def http_service
    HTTPClient.new
  end

  def format_slack_msg(msg, title, channel)
    channel.prepend("#") unless channel =~ /^#/

    aws_env = ENV.fetch("DEPLOY_ENV", "development")

    {
      username: "Caseflow (#{aws_env})",
      channel: channel,
      attachments: [
        {
          title: "#{title} (#{aws_env})",
          color: "#ccc",
          text: msg
        }
      ]
    }
  end
end
