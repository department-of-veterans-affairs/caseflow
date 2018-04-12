describe BusinessMetrics do
  context ".record" do
    subject { BusinessMetrics.record(service: :queue, name: "test") }

    it "sends business metrics to datadog service" do
      expect(DataDogService).to receive(:increment_counter).with(
        metric_group: "business",
        metric_name: "event",
        app_name: "other",
        attrs: {
          service: :queue,
          metric: "test"
        }
      )
      subject
    end
  end
end
