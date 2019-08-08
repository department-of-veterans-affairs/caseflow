# frozen_string_literal: true

class CaseflowJob < ApplicationJob
  def slack_url
    ENV["SLACK_DISPATCH_ALERT_URL"]
  end

  def slack_service
    @slack_service ||= SlackService.new(url: slack_url)
  end

  def deploy_env
    ENV.fetch("DEPLOY_ENV", "development")
  end
end
