# frozen_string_literal: true

describe JobTimeZoneMiddleware do
  before do
    Timecop.freeze(Time.new(2024, 10, 31, 2, 2, 2, "-08:00"))

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
      expect(Time.zone.name).to eq("Pacific Time (US & Canada)")
      call
      expect(@yield_called).to be_truthy
      expect(Time.zone.name).to eq("UTC")
    end
  end
end
