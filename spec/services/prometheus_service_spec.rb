describe PrometheusService do
  context "PrometheusGaugeSummary" do
    before do
      @gauge = Prometheus::Client::Gauge.new(:foo_gauge, "foo")
      @summary = Prometheus::Client::Summary.new(:foo_summary, "foo")
      @metric = PrometheusGaugeSummary.new(@gauge, @summary)
      TimeCop.freeze
    end

    context ".set" do
      before do
        @metric.set({}, 5)
      end

      it "sets values for gauge & summary" do
        expect(@gauge.values[{}]).to eq(5)
        expect(@summary.values[{}][0.5]).to eq(5)
      end

      it "sets a summary observation at most once every minute" do

      end
    end
  end
end
