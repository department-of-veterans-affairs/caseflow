require "dogapi"

class DataDogService
  datadog_api_key = ENV["DATADOG_API_KEY"]
  if datadog_api_key.nil?
    Rails.logger.warn "Env var DATADOG_API_KEY is not set, so DataDog metrics will not be tracked."
    # Setting the API key to an empty string will make tracking requests silently fail, which is what we want.
    datadog_api_key = ""
  end

  @dog = Dogapi::Client.new(datadog_api_key)

  # rubocop:disable Metrics/ParameterLists
  def self.emit_datadog_point(
    metric_group:, metric_name:, metric_value:, app_name:, attrs: {}, metric_type: "counter"
  )
    extra_tags = attrs.reduce([]) do |tags, (key, val)|
      tags << "#{key}:#{val}"
    end
    @dog.emit_point("dsva-appeals.#{metric_group}.#{metric_name}", metric_value,
                    host: `hostname`.strip, type: metric_type,
                    tags: [
                      "app:#{app_name}",
                      "env:#{Rails.env}"
                    ] + extra_tags)
  end
end
