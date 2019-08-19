# frozen_string_literal: true

class CaseflowJob < ApplicationJob
  def slack_url
    ENV["SLACK_DISPATCH_ALERT_URL"]
  end

  def slack_service
    @slack_service ||= SlackService.new(url: slack_url)
  end

  def datadog_service(:app_name, :metric_group_name)
    @datadog_service ||= DataDogService.new(app_name, metric_group_name)
  end
end
