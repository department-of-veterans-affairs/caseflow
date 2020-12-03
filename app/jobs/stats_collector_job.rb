# frozen_string_literal: true

# Designed to run daily to collect statistics about appeals in a single CaseflowJob.
# Runs daily stats collection every day, in the early morning.
# Runs weekly stats collection every Sunday, in the early morning.
# Runs monthly stats collection every 1st day of the month, in the early morning.
#
# This is a harness that can be extended with collectors that plug into `*_COLLECTORS` hashes.
# See Collectors::RequestIssuesStatsCollector as an example.
class StatsCollectorJob < CaseflowJob
  # For time_ago_in_words()
  include ActionView::Helpers::DateHelper

  queue_with_priority :low_priority
  application_attr :stats

  APP_NAME = "caseflow_job"
  METRIC_GROUP_NAME = name.underscore

  DAILY_COLLECTORS = {
    "daily_counts" => Collectors::DailyCountsStatsCollector
  }.freeze
  WEEKLY_COLLECTORS = {
  }.freeze
  MONTHLY_COLLECTORS = {
    "unidentified_request_issues_with_contention" => Collectors::RequestIssuesStatsCollector
  }.freeze

  def perform
    RequestStore.store[:current_user] = User.system_user

    run_collectors(DAILY_COLLECTORS)

    run_collectors(WEEKLY_COLLECTORS) if Time.zone.today.sunday?

    run_collectors(MONTHLY_COLLECTORS) if Time.zone.today.day == 1

    log_success
  rescue StandardError => error
    log_error(self.class.name, error)
  ensure
    datadog_report_runtime(metric_group_name: METRIC_GROUP_NAME)
  end

  protected

  def run_collectors(stats_collectors)
    stats_collectors.each do |collector_name, collector|
      start_time = Time.zone.now

      collector.new.collect_stats&.each { |obj| emit_or_fail(obj) }
    rescue StandardError => error
      log_error(collector_name, error)
    ensure
      datadog_report_time_segment(segment: "#{METRIC_GROUP_NAME}.#{collector_name}", start_time: start_time)
    end
  end

  def emit_or_fail(hash)
    # when hash is { metric: metric_name", value: 123, "some_tag": "type1" }
    return emit_tagged_hash(hash) if tagged_hash?(hash)

    # when hash is { "metric_name" => 123 }
    return emit_untagged_hash(hash) if hash.size == 1

    fail "Unexpect metric object: #{hash}"
  end

  # :reek:FeatureEnvy
  def tagged_hash?(hash)
    hash[:metric] && hash[:value]
  end

  # :reek:FeatureEnvy
  def emit_tagged_hash(hash)
    emit(hash[:metric], hash[:value], tags: hash.except(:metric, :value))
  end

  # :reek:FeatureEnvy
  def emit_untagged_hash(hash)
    emit(hash.first[0], hash.first[1])
  end

  def emit(name, value, tags: {})
    DataDogService.emit_gauge(
      metric_group: METRIC_GROUP_NAME,
      metric_name: name,
      metric_value: value,
      app_name: APP_NAME,
      attrs: tags
    )
  end

  def log_success
    duration = time_ago_in_words(start_time)
    msg = "#{self.class.name} completed after running for #{duration}."
    Rails.logger.info(msg)

    slack_service.send_notification("[INFO] #{msg}", self.class.to_s) # may not need this
  end

  def log_error(collector_name, err)
    duration = time_ago_in_words(start_time)
    msg = "#{collector_name} failed after running for #{duration}. Fatal error: #{err.message}"
    Rails.logger.info(msg)
    Rails.logger.info(err.backtrace.join("\n"))

    Raven.capture_exception(err, extra: { stats_collector_name: collector_name })

    slack_service.send_notification("[ERROR] #{msg}", self.class.to_s)
  end
end
