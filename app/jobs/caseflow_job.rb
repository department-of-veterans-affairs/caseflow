# frozen_string_literal: true

class CaseflowJob < ApplicationJob
  attr_accessor :start_time

  before_perform do |job|
    job.start_time = Time.zone.now
  end

  def datadog_report_runtime(metric_group_name:)
    DataDogService.record_runtime(
      app_name: "caseflow_job",
      metric_group: metric_group_name,
      start_time: @start_time
    )
  end

  def slack_url
    ENV["SLACK_DISPATCH_ALERT_URL"]
  end

  def slack_service
    @slack_service ||= SlackService.new(url: slack_url)
  end
end
