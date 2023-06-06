# frozen_string_literal: true

require "benchmark"

# see https://dropwizard.github.io/metrics/3.1.0/getting-started/ for abstractions on metric types
class MetricsService
  def self.record(description, service: nil, name: "unknown", caller)
    return_value = nil
    app = RequestStore[:application] || "other"
    service ||= app
    uuid = SecureRandom.uuid
    metric_name= 'request_latency'
    sent_to = [[Metric::LOG_SYSTEMS[:rails_console]]]
    sent_to_info = nil

    Rails.logger.info("STARTED #{description}")
    stopwatch = Benchmark.measure do
      return_value = yield
    end

    if service
      latency = stopwatch.real
      sent_to_info = {
        metric_group: "service",
        metric_name: metric_name,
        metric_value: latency,
        app_name: app,
        attrs: {
          service: service,
          endpoint: name,
          uuid: uuid
        }
      }
      DataDogService.emit_gauge(sent_to_info)

      sent_to << Metric::LOG_SYSTEMS[:datadog]
    end

    Rails.logger.info("FINISHED #{description}: #{stopwatch}")
    metric_params = {
      name: metric_name,
      message: description,
      product: service&.to_s,
      app_name: app,
      attrs: {
        service: service,
        endpoint: name
      },
      sent_to: sent_to,
      sent_to_info: sent_to_info,
      duration: stopwatch.total
    }
    store_record_metric(uuid, metric_params, caller)

    return_value
  rescue StandardError
    increment_datadog_counter("request_error", service, name, app) if service

    metric_params[:type] = Metric::METRIC_TYPES[:error]
    store_record_metric(uuid, metric_params, caller)

    # Re-raise the same error. We don't want to interfere at all in normal error handling.
    # This is just to capture the metric.
    raise
  ensure
    increment_datadog_counter("request_attempt", service, name, app) if service
  end

  private_class_method def self.increment_datadog_counter(metric_name, service, endpoint_name, app_name)
    DataDogService.increment_counter(
      metric_group: "service",
      metric_name: metric_name,
      app_name: app_name,
      attrs: {
        service: service,
        endpoint: endpoint_name
      }
    )

    private

    def self.store_record_metric(uuid, params, caller)
      name ="caseflow.server.metric.#{params[:name]&.downcase.gsub(/::/, '.')}"
      params = {
        uuid: uuid,
        name: name,
        message: params[:message],
        type: params[:type] || Metric::METRIC_TYPES[:performance],
        product: params[:product],
        app_name: params[:app_name],
        metric_attributes: params[:attrs],
        sent_to: params[:sent_to],
        sent_to_info: params[:sent_to_info],
        duration: params[:duration],
      }
      Metric.create_metric(caller || self, params, RequestStore[:current_user])
    end
  end
end
