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
    let(:hearing) do
      create(
        :hearing,
        scheduled_in_timezone: "America/Los_Angeles"
      )
    end

    let(:legacy_hearing) do
      create(
        :legacy_hearing,
        scheduled_in_timezone: "America/Los_Angeles"
      )
    end

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

    context "hearing is AMA" do
      describe "local_time" do
        it "returns the scheduled_for value for a hearing" do
          time_service = described_class.new(hearing: hearing)

          expect(time_service.local_time).to eq(hearing.scheduled_for)
          expect(time_service.local_time.zone).to eq(hearing.scheduled_for.zone)
        end
      end

      describe "central_office_time" do
        it "returns local_time in Eastern Time" do
          time_service = described_class.new(hearing: hearing)

          if time_service.central_office_time.dst?
            expect(time_service.central_office_time.zone).to eq("EDT")
          else
            expect(time_service.central_office_time.zone).to eq("EST")
          end
        end
      end

      describe "central_office_time_string" do
        it "formats central_office_time into a string" do
          time_service = described_class.new(hearing: hearing)
          expected_string = hearing
                              .scheduled_for
                              .in_time_zone("America/New_York")
                              .strftime("%Y-%m-%d %I:%M %p %z")

          expect(time_service.central_office_time_string).to eq(expected_string)
        end
      end

      describe "scheduled_time_string" do
        it "formats local_time into a string" do
          time_service = described_class.new(hearing: hearing)
          expected_string = "#{hearing.scheduled_for.strftime('%l:%M %p')} Pacific Time (US & Canada)".lstrip

          expect(time_service.scheduled_time_string).to eq(expected_string)
        end
      end
    end
    context "hearing is Legacy" do
      describe "local_time" do
        xit "returns the scheduled_for value for a hearing" do
          # skipping until LegacyHearing#scheduled_for is implemented
        end
      end

      describe "central_office_time" do
        xit "returns local_time in Eastern Time" do
          # skipping until LegacyHearing#scheduled_for is implemented
        end
      end

      describe "central_office_time_string" do
        xit "formats central_office_time into a string" do
          # skipping until LegacyHearing#scheduled_for is implemented
        end
      end

      describe "scheduled_time_string" do
        xit "formats local_time into a string" do
          # skipping until LegacyHearing#scheduled_for is implemented
        end
      end
    end
  end
end
