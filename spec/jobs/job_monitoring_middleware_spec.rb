# frozen_string_literal: true

describe JobMonitoringMiddleware do
  before do
    Timecop.freeze(Time.utc(2017, 2, 2))

    @middleware = JobMonitoringMiddleware.new
    @msg = {
      "args" => [{
        "job_class" => "FunTestJob"
      }]
    }
    @body = {
      "job_class" => "FunTestJob"
    }
    @yield_called = false
  end

  context ".call" do
    let(:call) { @middleware.call(nil, nil, @msg, @body) { @yield_called = true } }
    let(:last_started_at) { Rails.cache.read("FunTestJob_last_started_at") }
    let(:last_completed_at) { Rails.cache.read("FunTestJob_last_completed_at") }

    it "sets started & completed timestamps" do
      expect(@yield_called).to be_falsey
      call
      expect(@yield_called).to be_truthy
      expect(last_started_at).to eq(Time.now.utc)
      expect(last_completed_at).to eq(Time.now.utc)
    end
  end
end
