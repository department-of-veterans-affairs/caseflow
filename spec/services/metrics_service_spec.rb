describe MetricsService do
  context ".timer" do
    before do
      RequestStore.store[:application] = "fake-app"
    end
    let(:yield_val) { 5 }
    subject do
      MetricsService.timer("fake api call", service: "vbms", name: "GoodInfo") { yield_val }
    end

    it "returns yield value" do
      expect(subject).to eq(yield_val)
    end

    it "sends prometheus metrics" do
      subject
      gauge = PrometheusService.vbms_request_latency.gauge
      labels = gauge.values.keys.first
      expect(labels[:app]).to eq("fake-app")
      expect(labels[:name]).to eq("GoodInfo")

      # Ensure a value has been assigned
      expect(gauge.values[labels]).to be_truthy
    end
  end
end
