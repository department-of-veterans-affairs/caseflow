# frozen_string_literal: true

RSpec.describe HearingDatetimeService do
  context "class methods" do
    describe "prepare_datetime_for_storage" do
      it "returns a Time object" do
        date = "2021-02-03"
        time_string = "1:00 PM Central Time (US & Canada)"

        time = described_class.prepare_datetime_for_storage(date: date, time_string: time_string)

        expect(time).to be_a(Time)
      end

      it "has the correct Daylight Savings time offset in Summer" do
        date = "2021-07-03"
        time_string = "1:00 PM Central Time (US & Canada)"

        time = described_class.prepare_datetime_for_storage(date: date, time_string: time_string)
        expected_time = Time.new(2021, 7, 3, 13, 0, 0, "-05:00")

        expect(time.dst?).to eq(true)
        expect(time.zone).to eq("CDT")
        expect(time).to eq(expected_time)
      end

      it "has no Daylight Savings time offset in Winter" do
        date = "2026-02-06"
        time_string = "1:00 PM Central Time (US & Canada)"

        time = described_class.prepare_datetime_for_storage(date: date, time_string: time_string)
        expected_time = Time.new(2026, 2, 6, 13, 0, 0, "-06:00")

        expect(time.dst?).to eq(false)
        expect(time.zone).to eq("CST")
        expect(time).to eq(expected_time)
      end

      it "has no DST offset in Summer for zone that does not observe DST" do
        date = "2021-07-03"
        time_string = "1:00 PM Arizona"

        time = described_class.prepare_datetime_for_storage(date: date, time_string: time_string)
        expected_time = Time.new(2021, 7, 3, 13, 0, 0, "-07:00")

        expect(time.dst?).to eq(false)
        expect(time.zone).to eq("MST")
        expect(time).to eq(expected_time)
      end

      it "edge case: returns the correct time for error-prone Manila timezone: Summer" do
        # NOTE: Asia/Manila tz does not observe Daylight Savings Time
        date = "2021-07-03"
        time_string = "1:00 PM Philippine Standard Time"

        time = described_class.prepare_datetime_for_storage(date: date, time_string: time_string)
        expected_time = Time.new(2021, 7, 3, 13, 0, 0, "+08:00")

        expect(time.dst?).to eq(false)
        expect(time.zone).to eq("PST")
        expect(time).to eq(expected_time)
      end

      it "edge case: returns the correct time for error-prone Manila timezone: Winter" do
        date = "2021-01-03"
        time_string = "1:00 PM Philippine Standard Time"

        time = described_class.prepare_datetime_for_storage(date: date, time_string: time_string)
        expected_time = Time.new(2021, 1, 3, 13, 0, 0, "+08:00")

        expect(time.dst?).to eq(false)
        expect(time.zone).to eq("PST")
        expect(time).to eq(expected_time)
      end

      it "returns nil if date method argument is nil" do
        date = nil
        time_string = "1:00 PM Central Time (US & Canada)"

        time = described_class.prepare_datetime_for_storage(date: date, time_string: time_string)

        expect(time).to eq(nil)
      end

      it "returns nil if time_string method argument is nil" do
        date = "2021-02-03"
        time_string = nil

        time = described_class.prepare_datetime_for_storage(date: date, time_string: time_string)

        expect(time).to eq(nil)
      end

      it "raises error if the timezone in the time_string is bogus" do
        date = "2021-02-03"
        time_string = "1:00 PM Fantasy Land Timezone"

        expect do
          described_class.prepare_datetime_for_storage(date: date, time_string: time_string)
        end.to raise_error(TZInfo::InvalidTimezoneIdentifier)
      end
    end
  end

  context "instance methods" do
    let(:summer_date) { "2030-06-01".to_date }
    let(:winter_date) { "2030-12-01".to_date }

    let(:hearing) do
      create(
        :hearing,
        scheduled_in_timezone: "America/Los_Angeles",
        hearing_day: create(
          :hearing_day,
          scheduled_for: winter_date
        )
      )
    end

    let(:summer_hearing) do
      create(
        :hearing,
        scheduled_in_timezone: "America/Los_Angeles",
        hearing_day: create(
          :hearing_day,
          scheduled_for: summer_date
        )
      )
    end

    let(:legacy_hearing) do
      create(
        :legacy_hearing,
        scheduled_in_timezone: "America/Los_Angeles",
        hearing_day: create(
          :hearing_day,
          scheduled_for: winter_date
        )
      )
    end

    let(:summer_legacy_hearing) do
      create(
        :legacy_hearing,
        scheduled_in_timezone: "America/Los_Angeles",
        hearing_day: create(
          :hearing_day,
          scheduled_for: summer_date
        )
      )
    end

    # to test validations in initializer
    let(:hearing_2) do
      create(
        :hearing,
        scheduled_in_timezone: nil
      )
    end

    # to test validations in initializer
    let(:legacy_hearing_2) do
      create(
        :legacy_hearing,
        scheduled_in_timezone: nil
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

      it "validates the hearing's scheduled_in_timezone value" do
        expect do
          described_class.new(hearing: hearing_2)
        end.to raise_error(HearingDatetimeService::UnsuppliedScheduledInTimezoneError)

        expect do
          described_class.new(hearing: legacy_hearing_2)
        end.to raise_error(HearingDatetimeService::UnsuppliedScheduledInTimezoneError)
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
          time_service_2 = described_class.new(hearing: summer_hearing)

          expect(time_service.central_office_time.zone).to eq("EST")
          expect(time_service_2.central_office_time.zone).to eq("EDT")
        end
      end

      describe "central_office_time_string" do
        it "formats central_office_time into a string" do
          time_service = described_class.new(hearing: hearing)
          expected_string = hearing
            .scheduled_for
            .in_time_zone("America/New_York")
            .strftime("%l:%M %p")
            .lstrip
            .concat(" ", "Eastern Time (US & Canada)")

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
        it "returns the scheduled_for value for a hearing" do
          time_service = described_class.new(hearing: legacy_hearing)

          expect(time_service.local_time).to eq(legacy_hearing.scheduled_for)
          expect(time_service.local_time.zone).to eq(legacy_hearing.scheduled_for.zone)
        end
      end

      describe "central_office_time" do
        it "returns local_time in Eastern Time" do
          time_service = described_class.new(hearing: legacy_hearing)
          time_service_2 = described_class.new(hearing: summer_legacy_hearing)

          expect(time_service.central_office_time.zone).to eq("EST")
          expect(time_service_2.central_office_time.zone).to eq("EDT")
        end
      end

      describe "central_office_time_string" do
        it "formats central_office_time into a string" do
          time_service = described_class.new(hearing: legacy_hearing)
          expected_string = legacy_hearing
            .scheduled_for
            .in_time_zone("America/New_York")
            .strftime("%l:%M %p")
            .lstrip
            .concat(" ", "Eastern Time (US & Canada)")

          expect(time_service.central_office_time_string).to eq(expected_string)
        end
      end

      describe "scheduled_time_string" do
        it "formats local_time into a string" do
          time_service = described_class.new(hearing: legacy_hearing)
          expected_string = "#{legacy_hearing.scheduled_for.strftime('%l:%M %p')} Pacific Time (US & Canada)".lstrip

          expect(time_service.scheduled_time_string).to eq(expected_string)
        end
      end

      describe "process_legacy_scheduled_time_string" do
        it "is an alias for .prepare_datetime_for_storage" do
          date = "2024-01-01"
          time_string = "11:00 AM Central Time (US & Canada)"

          time_prepped = described_class.prepare_datetime_for_storage(date: date, time_string: time_string)
          time_legacy_processed = legacy_hearing.time.process_legacy_scheduled_time_string(
            date: date,
            time_string: time_string
          )

          expected_time = Time.new(2024, 1, 1, 11, 0, 0, "-06:00")

          expect(time_prepped).to eq(expected_time)
          expect(time_legacy_processed).to eq(expected_time)
          expect(time_prepped).to eq(time_legacy_processed)
        end
      end
    end
  end
end
