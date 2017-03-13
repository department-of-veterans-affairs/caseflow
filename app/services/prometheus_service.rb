class PrometheusService
  def self.completed_vbms_requests
    @completed_vbms_requests ||= Prometheus::Client.registry.counter(:completed_vbms_requests, 'A counter of completed VBMS requests')
  end
end
