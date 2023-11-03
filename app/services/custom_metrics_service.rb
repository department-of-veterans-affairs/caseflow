# frozen_string_literal: true

# ManagedDynatrace for Government	https://{your-domain}/e/{your-environment-id}/api/v2/metrics/ingest
BASE_URL = ENV[""]

# https://docs.dynatrace.com/docs/extend-dynatrace/extend-metrics/reference/custom-metric-metadata#properties
#

class CustomMetricsService
  def self.increment_counter(metric_group:, metric_name:, app_name:, attrs: {}, by: 1)
    tags = get_tags(app_name, attrs)
    stat_name = get_stat_name(metric_group, metric_name)
    #build request
    request = HTTPI::Request.new(BASE_URL)
    request.open_timeout = 300
    request.read_timeout = 300
    request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]

    #build body
    request.body = render json: {
      displayName: stat_name,
      description: "",
      unit: "Unspecified",
      tags: tags,
      }

    HTTPI.post(request)
  end

  def self.record_runtime(metric_group:, app_name:, start_time: Time.zone.now)
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

    #build request
    request = HTTPI::Request.new(BASE_URL)
    request.open_timeout = 300
    request.read_timeout = 300
    request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]

    #build body
    request.body = render json: {
      displayName: stat_name,
      description: "",
      unit: "Unspecified",
      tags: tags,
      }

    HTTPI.post(request)
  end

  # :nocov:
  def self.histogram(metric_group:, metric_name:, metric_value:, app_name:, attrs: {})
    tags = get_tags(app_name, attrs)
    stat_name = get_stat_name(metric_group, metric_name)

    #build request
    request = HTTPI::Request.new(BASE_URL)
    request.open_timeout = 300
    request.read_timeout = 300
    request.auth.ssl.ca_cert_file = ENV["SSL_CERT_FILE"]

    #build body
    request.body = render json: {
      displayName: stat_name,
      description: "",
      unit: "Unspecified",
      tags: tags,
      }

    HTTPI.post(request)
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

# TODO  exception handleing
# Response codes
# Code	Type	Description
# 202	ValidationResponse
# The provided metric data points are accepted and will be processed in the background.

# 400	ValidationResponse
# Some data points are invalid. Valid data points are accepted and will be processed in the background.

=begin
Example JSON
{
  "displayName": "Total revenue",
  "description": "Total store revenue by region, city, and store",
  "unit": "Unspecified",
  "tags": ["KPI", "Business"],
  "metricProperties": {
    "maxValue": 1000000,
    "minValue": 0,
    "rootCauseRelevant": false,
    "impactRelevant": true,
    "valueType": "score",
    "latency": 1
  },
  "dimensions": [
    {
      "key": "city",
      "displayName": "City name"
    },
    {
      "key": "country",
      "displayName": "Country name"
    },
    {
      "key": "region",
      "displayName": "Sales region"
    },
    {
      "key": "store",
      "displayName": "Store #"
    }
  ]
}

Payload required
The general format of the payload is the following:

format,dataPoint timestamp

=end
