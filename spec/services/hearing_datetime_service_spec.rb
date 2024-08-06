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

        expect(time.dst?).to eq(true)
        expect(time.zone).to eq("CDT")
        # utc_offset is in seconds
        expect(time.utc_offset).to eq(-18000)
      end

      it "has no Daylight Savings time offset in Winter" do
        date = "2026-02-06"
        time_string = "1:00 PM Central Time (US & Canada)"

        time = described_class.prepare_time_for_storage(date: date, time_string: time_string)

        expect(time.dst?).to eq(false)
        expect(time.zone).to eq("CST")
        # utc_offset is in seconds
        expect(time.utc_offset).to eq(-21600)
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
        end.to raise_error(TZInfo::UnknownTimezone)
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
