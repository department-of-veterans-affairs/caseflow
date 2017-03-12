class PrometheusService
  def self.vbms_errors_counter
    @vbms_errors_counter ||= Prometheus::Client.registry.counter(:vbms_errors, 'A counter of VBMS errors')
  end
end
