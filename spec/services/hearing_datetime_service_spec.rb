# frozen_string_literal: true

RSpec.describe HearingDatetimeService do
  context "class methods" do
    describe "prepare_time_for_storage" do
      it "returns a Time object" do
        date = "2021-02-03"
        time_string = "1:00 PM Central Time (US & Canada)"

        time = described_class.prepare_time_for_storage(date: date, time_string: time_string)

        expect(time).to be_a(Time)
      end

      it "has the correct Daylight Savings time offset in Summer" do
        date = "2021-07-03"
        time_string = "1:00 PM Central Time (US & Canada)"

        time = described_class.prepare_time_for_storage(date: date, time_string: time_string)
        expected_time = Time.new(2021, 7, 3, 13, 0, 0, "-05:00")

        expect(time.dst?).to eq(true)
        expect(time.zone).to eq("CDT")
        expect(time).to eq(expected_time)
      end

      it "has no Daylight Savings time offset in Winter" do
        date = "2026-02-06"
        time_string = "1:00 PM Central Time (US & Canada)"

        time = described_class.prepare_time_for_storage(date: date, time_string: time_string)
        expected_time = Time.new(2026, 2, 6, 13, 0, 0, "-06:00")

        expect(time.dst?).to eq(false)
        expect(time.zone).to eq("CST")
        expect(time).to eq(expected_time)
      end

      it "has no DST offset in Summer for zone that does not observe DST" do
        date = "2021-07-03"
        time_string = "1:00 PM Arizona"

        time = described_class.prepare_time_for_storage(date: date, time_string: time_string)
        expected_time = Time.new(2021, 7, 3, 13, 0, 0, "-07:00")

        expect(time.dst?).to eq(false)
        expect(time.zone).to eq("MST")
        expect(time).to eq(expected_time)
      end

      it "edge case: returns the correct time for error-prone Manila timezone: Summer" do
        # note Asia/Manila tz does not observe Daylight Savings Time
        date = "2021-07-03"
        time_string = "1:00 PM Philippine Standard Time"

        time = described_class.prepare_time_for_storage(date: date, time_string: time_string)
        expected_time = Time.new(2021, 7, 3, 13, 0, 0, "+08:00")

        expect(time.dst?).to eq(false)
        expect(time.zone).to eq("PST")
        expect(time).to eq(expected_time)
      end

      it "edge case: returns the correct time for error-prone Manila timezone: Winter" do
        date = "2021-01-03"
        time_string = "1:00 PM Philippine Standard Time"

        time = described_class.prepare_time_for_storage(date: date, time_string: time_string)
        expected_time = Time.new(2021, 1, 3, 13, 0, 0, "+08:00")

        expect(time.dst?).to eq(false)
        expect(time.zone).to eq("PST")
        expect(time).to eq(expected_time)
      end

      it "returns nil if date method argument is nil" do
        date = nil
        time_string = "1:00 PM Central Time (US & Canada)"

        time = described_class.prepare_time_for_storage(date: date, time_string: time_string)

        expect(time).to eq(nil)
      end

      it "returns nil if time_string method argument is nil" do
        date = "2021-02-03"
        time_string = nil

        time = described_class.prepare_time_for_storage(date: date, time_string: time_string)

        expect(time).to eq(nil)
      end

      it "raises error if the timezone in the time_string is bogus" do
        date = "2021-02-03"
        time_string = "1:00 PM Fantasy Land Timezone"

        expect do
          described_class.prepare_time_for_storage(date: date, time_string: time_string)
        end.to raise_error(TZInfo::InvalidTimezoneIdentifier)
      end
    end
  end

  context "instance methods" do
    let(:hearing) { create(:hearing) }
    let(:legacy_hearing) { create(:legacy_hearing) }

    describe "initialize" do
      it "exists" do
        expect(described_class.new(hearing: hearing)).to be_a(HearingDatetimeService)
      end

      it "can be initialized with AMA or Legacy Hearing" do
        time_service_1 = described_class.new(hearing: hearing)
        time_service_2 = described_class.new(hearing: legacy_hearing)

        expect(time_service_1.instance_variable_get(:@hearing)).to be_a(Hearing)
        expect(time_service_2.instance_variable_get(:@hearing)).to be_a(LegacyHearing)
      end
    end
  end
end
