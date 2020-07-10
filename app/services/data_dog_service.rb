# frozen_string_literal: true

require "datadog/statsd"

class DataDogService
  @statsd = Datadog::Statsd.new

  def self.increment_counter(metric_group:, metric_name:, app_name:, attrs: {}, by: 1)
    tags = get_tags(app_name, attrs)
    stat_name = get_stat_name(metric_group, metric_name)
    @statsd.increment(stat_name, tags: tags, by: by)
  end

  def self.record_runtime(metric_group:, app_name:, start_time:)
    metric_name = "runtime"
    job_duration_seconds = Time.zone.now - start_time

    emit_gauge(
      app_name: app_name,
      metric_group: metric_group,
      metric_name: metric_name,
      metric_value: job_duration_seconds
    )
  end

  def self.emit_gauge(metric_group:, metric_name:, metric_value:, app_name:, attrs: {})
    tags = get_tags(app_name, attrs)
    stat_name = get_stat_name(metric_group, metric_name)
    @statsd.gauge(stat_name, metric_value, tags: tags)
  end

  # :nocov:
  def self.histogram(metric_group:, metric_name:, metric_value:, app_name:, attrs: {})
    tags = get_tags(app_name, attrs)
    stat_name = get_stat_name(metric_group, metric_name)
    @statsd.histogram(stat_name, metric_value, tags: tags)
  end
  # :nocov:

  private_class_method def self.get_stat_name(metric_group, metric_name)
    "dsva-appeals.#{metric_group}.#{metric_name}"
  end

  private_class_method def self.get_tags(app_name, attrs)
    extra_tags = attrs.reduce([]) do |tags, (key, val)|
      tags + ["#{key}:#{val}"]
    end
    [
      "app:#{app_name}",
      "env:#{Rails.current_env}"
    ] + extra_tags
  end
end
