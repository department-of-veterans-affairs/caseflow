require "dogapi"

class DataDogService
  datadog_api_key = ENV["DATADOG_API_KEY"]
  if datadog_api_key.nil?
    Rails.logger.warn "Env var DATADOG_API_KEY is not set, so DataDog metrics will not be tracked."
    # Setting the API key to an empty string will make tracking requests silently fail, which is what we want.
    datadog_api_key = ""
  end

  @dog = Dogapi::Client.new(datadog_api_key)
  @host = `curl http://instance-data/latest/meta-data/instance-id --silent || echo "not-ec2"`.strip

  def self.increment_counter(metric_group:, metric_name:, app_name:, attrs: {})
    emit_datadog_point(
      metric_group: metric_group, metric_name: metric_name, app_name: app_name,
      attrs: attrs, metric_type: "counter", metric_value: 1)
  end

  def self.emit_gauge(metric_group:, metric_name:, metric_value:, app_name:, attrs: {})
    emit_datadog_point(
      metric_group: metric_group, metric_name: metric_name, metric_value: metric_value, app_name: app_name,
      attrs: attrs, metric_type: "gauge")
  end

  # rubocop:disable Metrics/ParameterLists
  private_class_method def self.emit_datadog_point(
    metric_group:, metric_name:, metric_value:, app_name:, attrs:, metric_type:
  )
    extra_tags = attrs.reduce([]) do |tags, (key, val)|
      tags << "#{key}:#{val}"
    end
    @dog.emit_point("dsva-appeals.#{metric_group}.#{metric_name}", metric_value,
                    host: @host, type: metric_type,
                    tags: [
                      "app:#{app_name}",
                      "env:#{Rails.env}"
                    ] + extra_tags)
  end
end
