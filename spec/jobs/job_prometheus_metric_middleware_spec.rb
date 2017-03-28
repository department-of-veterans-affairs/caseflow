describe JobPrometheusMetricMiddleware do
  before do
    @middleware = JobPrometheusMetricMiddleware.new

    @msg = {
      "args" => [{
        "job_class" => "FunTestJob"
      }]
    }
    @yield_called = false
    allow(PrometheusService).to receive(:push_metrics!).and_return(nil)
    @labels = { name: "FunTestJob" }
  end


  context ".call" do
    let (:call) { @middleware.call(nil, @msg, :default) { @yield_called = true } }

    it "always increments attempts counter" do

      expect(PrometheusService.background_jobs_attempt_counter.values[@labels]).to eq(nil)
      expect(@yield_called).to be_falsey
      call
      expect(@yield_called).to be_truthy
      expect(PrometheusService.background_jobs_attempt_counter.values[@labels]).to eq(1)
    end

    it "increments error counter on error" do
      expect(PrometheusService.background_jobs_error_counter.values[@labels]).to eq(nil)
     expect {
       @middleware.call(nil, @msg, :default) { fail('test') }
     }.to raise_error

     expect(PrometheusService.background_jobs_error_counter.values[@labels]).to eq(1)
    end
  end
end
