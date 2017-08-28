require "prometheus/client"
require "prometheus/client/push"

class PrometheusService
  # :nocov:
  class << self
    def efolder_request_attempt_counter
      @efolder_request_attempt_counter ||=
        find_or_register_metric(:counter,
                                :efolder_request_attempt_counter,
                                "A counter of attempted eFolder requests")
    end

    def efolder_request_error_counter
      @efolder_request_error_counter ||=
        find_or_register_metric(:counter,
                                :efolder_request_error_counter,
                                "A counter of errored eFolder requests")
    end

    def efolder_request_latency
      @efolder_request_latency ||=
        find_or_register_gauge_and_summary(:efolder_request_latency,
                                           "latency of completed eFolder requests")
    end

    def vbms_request_attempt_counter
      @vbms_request_attempt_counter ||=
        find_or_register_metric(:counter,
                                :vbms_request_attempt_counter,
                                "A counter of attempted VBMS requests")
    end

    def vbms_request_error_counter
      @vbms_request_error_counter ||=
        find_or_register_metric(:counter,
                                :vbms_request_error_counter,
                                "A counter of errored VBMS requests")
    end

    def vbms_request_latency
      @vbms_request_latency ||=
        find_or_register_gauge_and_summary(:vbms_request_latency,
                                           "latency of completed VBMS requests")
    end

    def bgs_request_attempt_counter
      @bgs_request_attempt_counter ||=
        find_or_register_metric(:counter,
                                :bgs_request_attempt_counter,
                                "A counter of attempted BGS requests")
    end

    def bgs_request_error_counter
      @bgs_request_error_counter ||=
        find_or_register_metric(:counter,
                                :bgs_request_error_counter,
                                "A counter of errored BGS requests")
    end

    def bgs_request_latency
      @bgs_request_latency ||=
        find_or_register_gauge_and_summary(:bgs_request_latency,
                                           "latency of completed BGS requests")
    end

    def vacols_request_attempt_counter
      @vacols_request_attempt_counter ||=
        find_or_register_metric(:counter,
                                :vacols_request_attempt_counter,
                                "A counter of attempted VACOLS requests")
    end

    def vacols_request_error_counter
      @vacols_request_error_counter ||=
        find_or_register_metric(:counter,
                                :vacols_request_error_counter,
                                "A counter of errored VACOLS requests")
    end

    def vacols_request_latency
      @vacols_request_latency ||=
        find_or_register_gauge_and_summary(:vacols_request_latency,
                                           "latency of completed VACOLS requests")
    end

    def app_server_threads
      @app_server_threads ||=
        find_or_register_gauge_and_summary(:app_server_threads,
                                           "app server threads snapshot")
    end

    def postgres_db_connections
      @postgres_db_connections ||=
        find_or_register_gauge_and_summary(:postgres_db_connections,
                                           "postgres db connection snapshot")
    end

    def vacols_db_connections
      @vacols_db_connections ||=
        find_or_register_gauge_and_summary(:vacols_db_connections,
                                           "vacols db connection snapshot")
    end

    def background_jobs
      @background_jobs ||=
        find_or_register_gauge_and_summary(:background_jobs,
                                           "sidekiq background jobs")
    end

    def background_jobs_attempt_counter
      @background_jobs_attempt_counter ||=
        find_or_register_metric(:counter,
                                :background_jobs_attempt_counter,
                                "counter of all sidekiq background jobs attempted (fail or succeed)")
    end

    def background_jobs_error_counter
      @background_jobs_error_counter ||=
        find_or_register_metric(:counter,
                                :background_jobs_error_counter,
                                "counter of all sidekiq background jobs that errored")
    end

    # This method pushes all registered metrics to the prometheus pushgateway
    def push_metrics!
      metrics = Prometheus::Client.registry
      url = Rails.application.secrets.prometheus_push_gateway_url

      return unless url
      Prometheus::Client::Push.new("push-gateway", nil, url).add(metrics)
    end

    private

    def find_or_register_gauge_and_summary(name, description)
      gauge = find_or_register_metric(:gauge, "#{name}_gauge".to_sym, description)
      summary = find_or_register_metric(:summary, "#{name}_summary".to_sym, description)
      PrometheusGaugeSummary.new(gauge, summary)
    end

    def find_metric(name)
      Prometheus::Client.registry.metrics.find { |m| m.name == name }
    end

    def find_or_register_metric(type, name, description)
      find_metric(name) || Prometheus::Client.registry.send(type, name, description)
    end
  end
  # :nocov:
end

# This class is a wrapper for gauge & summary metrics.
# In practice, we almost always want to create both a gauage
# and a summary. This class provides a simple `.set()` interface
# for updating both at the same time
class PrometheusGaugeSummary
  LAST_SUMMARY_OBSERVATION_REDIS_KEY_PREFIX = "prometheus_last_summary_observation".freeze
  SUMMARY_OBSERVATION_THRESHOLD = 1.minute

  attr_accessor :gauge, :summary
  def initialize(gauge, summary)
    @gauge = gauge
    @summary = summary
  end

  def set(label, value)
    gauge.set(label, value)
    record_summary_observation(label, value) if should_observe_summary?
  end

  def last_summary_observation
    Rails.cache.read(last_summary_observation_redis_key) || Time.at(0).utc
  end

  private

  def last_summary_observation_redis_key
    "#{LAST_SUMMARY_OBSERVATION_REDIS_KEY_PREFIX}_#{summary.name}"
  end

  def record_summary_observation(label, value)
    summary.observe(label, value)
    set_last_summary_observation
  end

  def set_last_summary_observation
    Rails.cache.write(last_summary_observation_redis_key, Time.now.utc)
  end

  def should_observe_summary?
    Time.now.utc > (last_summary_observation + SUMMARY_OBSERVATION_THRESHOLD)
  end
end
