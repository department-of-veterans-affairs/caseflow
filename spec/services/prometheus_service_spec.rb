describe PrometheusService do
  context "PrometheusGaugeSummary" do
    before do
      @gauge = Prometheus::Client::Gauge.new(:foo_gauge, "foo")
      @summary = Prometheus::Client::Summary.new(:foo_summary, "foo")
      @metric = PrometheusGaugeSummary.new(@gauge, @summary)
      @time = Timecop.freeze(Time.utc(2017, 2, 2))
    end

    context ".set" do
      before do
        @val = 5
        @metric.set({}, @val)
      end

      it "sets values for gauge & summary" do
        expect(@gauge.values[{}]).to eq(@val)
        expect(@summary.values[{}][0.5]).to eq(@val)
      end

      it "sets a summary observation at most once every 5 minutes" do
        new_val = 6
        expect(@metric.last_summary_observation).to eq(@time)

        # Call the metric set() again to record a 2nd value
        @metric.set({}, new_val)

        # Verify the gauge updated as expected
        expect(@gauge.values[{}]).to eq(new_val)

        # Verify the summary did *NOT* update
        expect(@summary.values[{}][0.5]).to eq(@val)

        new_time = Timecop.freeze(@time + 2.minutes)

        # Call the metric set() again to record a 3rd value
        @metric.set({}, new_val)

        # Since 5 minutes have passed,
        # verify the summary updated as expected,
        expect(@summary.values[{}][0.5]).to eq(new_val)
        expect(@metric.last_summary_observation).to eq(new_time)
      end

      it "does not clash with other summary metric's last_observation" do
        gauge2 = Prometheus::Client::Gauge.new(:bar_gauge, "bar")
        summary2 = Prometheus::Client::Summary.new(:bar_summary, "bar")
        metric2 = PrometheusGaugeSummary.new(gauge2, summary2)

        # Verify no last_summary_observation has been set
        expect(metric2.last_summary_observation).to eq(Time.at(0).utc)
        metric2.set({}, 10)
        expect(summary2.values[{}][0.5]).to eq(10)
      end
    end
  end
end
