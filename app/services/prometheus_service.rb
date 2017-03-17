class PrometheusService
  class << self
    def vbms_errors
      @vbms_errors ||=
        find_or_register_metric(:counter,
                                :vbms_errors,
                                "A counter of VBMS errored requests")
    end

    def completed_vbms_requests
      @completed_vbms_requests ||=
        find_or_register_metric(:counter,
                                :completed_vbms_requests,
                                "A counter of completed VBMS requests")
    end

    def app_server_threads
      @app_server_threads ||=
        find_or_register_gauge_and_summary(:app_server_threads,
                                          "app server threads snapshot")
    end

    def postgres_db_connections
      @app_server_threads ||=
        find_or_register_gauge_and_summary(:postgres_db_connections,
                                          "postgres db connection snapshot")
    end

    def vacols_db_connections
      @app_server_threads ||=
        find_or_register_gauge_and_summary(:vacols_db_connections,
                                          "vacols db connection snapshot")
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
end

# This class is a wrapper for gauge & summary metrics.
# In practice, we almost always want to create both a gauage
# and a summary. This class provides a simple `.set()` interface
# for updating both at the same time
class PrometheusGaugeSummary
  attr_accessor :gauge, :summary
  def initialize(gauge, summary)
    @gauge = gauge
    @summary = summary
  end

  def set(label, value)
    gauge.set(label, value)
    summary.observe(label, value)
  end
end
