# frozen_string_literal: true

class SlackService
  DEFAULT_CHANNEL = "#appeals-job-alerts"
  COLORS = {
    error: "#ff0000",
    info: "#cccccc",
    warn: "#ffff00"
  }.freeze

  def initialize(url:)
    @url = url
  end

  attr_reader :url

  def send_notification(msg, title = "", channel = DEFAULT_CHANNEL)
    return unless url && (aws_env != "uat")

    slack_msg = format_slack_msg(msg, title, channel)

    params = { body: slack_msg.to_json, headers: { "Content-Type" => "application/json" } }
    http_service.post(url, params)
  end

  private

  def http_service
    @http_service ||= begin
      # we do not want the self-signed cert normally part of the HTTPClient CA chain.
      client = HTTPClient.new
      client.ssl_config.clear_cert_store
      client.ssl_config.add_trust_ca(ENV["SSL_CERT_FILE"])
      client
    end
  end

  def pick_color(title, msg)
    if /error/i.match?(title)
      COLORS[:error]
    elsif /warn/i.match?(title)
      COLORS[:warn]
    elsif /error/i.match?(msg)
      COLORS[:error]
    elsif /warn/i.match?(msg)
      COLORS[:warn]
    else
      COLORS[:info]
    end
  end

  def format_slack_msg(msg, title, channel)
    channel.prepend("#") unless channel.match?(/^#/)

    {
      username: "Caseflow (#{aws_env})",
      channel: channel,
      attachments: [
        {
          title: title,
          color: pick_color(title, msg),
          text: msg
        }
      ]
    }
  end

  def aws_env
    ENV.fetch("DEPLOY_ENV", "development")
  end
end
