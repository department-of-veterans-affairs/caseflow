# frozen_string_literal: true

class CaseflowJob < ApplicationJob
  @start_time

  def datadog_report_runtime(:app_name, :metric_group_name)
    # TODO check for start time set
    DataDogService.record_runtime(
      app_name: app_name,
      metric_group_name: metric_group_name,
      start_time: @start_time
    )
  end

  def set_job_start_time(start_time: Time.zone.now)
    @start_time = start_time
  end

  def slack_url
    ENV["SLACK_DISPATCH_ALERT_URL"]
  end

  def slack_service
    @slack_service ||= SlackService.new(url: slack_url)
  end
end
