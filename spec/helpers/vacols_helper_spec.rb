describe VacolsHelper do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  context ".local_time_with_utc_timezone" do
    subject { VacolsHelper.local_time_with_utc_timezone }

    it "should be time in EST with UTC timezone" do
      now = Time.now
      expect(subject.hour).to eq now.hour
      expect(subject.zone).to eq "UTC"
    end
  end
end