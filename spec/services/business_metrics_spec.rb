# frozen_string_literal: true

describe BusinessMetrics do
  context ".record" do
    subject { BusinessMetrics.record(service: :queue, name: "test") }

    it "sends business metrics to metrics service" do
      RequestStore[:application] = "queue"
      expect(MetricsService).to receive(:increment_counter).with(
        metric_group: "business",
        metric_name: "event",
        app_name: "queue",
        attrs: {
          service: :queue,
          metric: "test"
        }
      )
      subject
    end
  end
end
