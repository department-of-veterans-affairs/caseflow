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

    private

    def find_metric(name)
      Prometheus::Client.registry.metrics.find { |m| m.name == name }
    end

    def find_or_register_metric(type, name, description)
      find_metric(name) || Prometheus::Client.registry.send(type, name, description)
    end
  end
end
