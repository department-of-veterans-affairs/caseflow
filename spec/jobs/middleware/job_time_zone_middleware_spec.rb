# frozen_string_literal: true

describe JobTimeZoneMiddleware do
  before do
    @middleware = JobTimeZoneMiddleware.new
    @msg = {
      "args" => [{
        "job_class" => "FunTestJob"
      }]
    }
    @body = {
      "job_class" => "FunTestJob"
    }
    @inside_tz = nil
    Time.zone = current_tz
  end

  context ".call" do
    let(:call) { @middleware.call(nil, nil, @msg, @body) { @inside_tz = Time.zone.name } }
    let(:current_tz) { "America/New_York" }

    it "changes timezone to UTC, then changes back" do
      expect(Time.zone.name).to eq(current_tz)
      expect(Rails.logger).to receive(:info).with(
        "FunTestJob current timezone is America/New_York"
      )
      call
      expect(@inside_tz).to eq("UTC")
      expect(Time.zone.name).to eq(current_tz)
    end
  end

  context ".call" do
    let(:call) { @middleware.call(nil, nil, @msg, @body) { @inside_tz = Time.zone.name } }
    let(:current_tz) { "UTC" }

    it "does not change timezone" do
      expect(Time.zone.name).to eq(current_tz)
      expect(Rails.logger).to_not receive(:info)
      call
      expect(@inside_tz).to eq("UTC")
      expect(Time.zone.name).to eq(current_tz)
    end
  end
end
