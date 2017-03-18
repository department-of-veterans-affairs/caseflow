describe PrometheusService do
  context "PrometheusGaugeSummary" do
    before do
      @gauge = Prometheus::Client::Gauge.new(:foo_gauge, "foo")
      @summary = Prometheus::Client::Summary.new(:foo_summary, "foo")
      @metric = PrometheusGaugeSummary.new(@gauge, @summary)
    end
    context ".set" do
      before do
        @metric.set({}, 5)
      end

      it "sets values for gauge & summary" do
        @gauge.values[{}] = 5
        @summary.values[{}] = 5
      end
    end
  end
end
