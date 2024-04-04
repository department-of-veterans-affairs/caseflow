# frozen_string_literal: true

class BusinessMetrics
  def self.record(service: nil, name: "unknown")
    app_name = RequestStore[:application] || "other"

    DataDogService.increment_counter(
      metric_group: "business",
      metric_name: "event",
      app_name: app_name,
      attrs: {
        service: service,
        metric: name
      }
    )
  end
end
