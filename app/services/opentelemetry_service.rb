# frozen_string_literal: true

require "opentelemetry/sdk"

class OpenTelemetryService
  @meter = OpenTelemetry.meter

  def increment_counter(metric_group:, metric_name:, app_name:, attrs: {})
    tags = attributes_to_tags(app_name, attrs)
    stat_name = get_stat_name(metric_group, metric_name)

    counter = @meter.create_integer_counter(
      name: stat_name,
      description: 'Description of the counter metric',
      unit: '1',
      labels: tags.keys
      )

      counter.add(1, labels: tags)
  end

  def emit_gauge(metric_group:, metric_name:, metric_value:, app_name:, attrs: {})
    tags = attributes_to_tags(app_name, attrs)
    stat_name = get_stat_name(metric_group, metric_name)

    gauge = @meter.create_double_gauge(
      name: stat_name,
      description: 'Description of the gauge metric',
      unit: '1',
      labels: tags.keys
      )

      gauge.set(metric_value, labels: tags)
  end

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
