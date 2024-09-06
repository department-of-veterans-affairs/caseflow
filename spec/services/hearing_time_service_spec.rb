# frozen_string_literal: true

describe HearingTimeService, :all_dbs do
  before do
    Timecop.freeze(Time.utc(2020, 1, 1, 0, 0, 0))
  end

  shared_context "legacy_hearing" do
    let!(:legacy_hearing) do
      # vacols requires us to pass a time set in ET even though it reflects local time
      # and is stored UTC
      create(
        :legacy_hearing,
        regional_office: "RO43",
        scheduled_for: Time.use_zone("America/New_York") { Time.zone.now.change(hour: 12, min: 0) }
      )
    end
  end

  context "with a legacy hearing and a hearing scheduled for 12:00pm PT" do
    include_context "legacy_hearing"

    let!(:hearing) { create(:hearing, regional_office: "RO43", scheduled_time: "12:00 PM") }

    describe "#local_time" do
      it "returns time object encoded in local time" do
        hearing_day = hearing.hearing_day
        expected_time = Time.use_zone("America/Los_Angeles") do
          Time.zone.now.change(
            year: hearing_day.scheduled_for.year,
            month: hearing_day.scheduled_for.month,
            day: hearing_day.scheduled_for.day,
            hour: 12,
            min: 0
          )
        end

        expect(LegacyHearing.first.time.local_time).to eq(expected_time)
        expect(hearing.time.local_time).to eq(expected_time)
      end
    end

    describe "#scheduled_time_string" do
      it "converts time to local time in HH:mm string" do
        expect(LegacyHearing.first.time.scheduled_time_string).to eq("12:00 PM Pacific Time (US & Canada)")
        expect(hearing.time.scheduled_time_string).to eq("12:00 PM Pacific Time (US & Canada)")
      end
    end

    describe "#central_office_time" do
      it "changes to central office timezone (ET)" do
        expected_time = Time.use_zone("America/New_York") { Time.zone.now.change(hour: 15, min: 0) }
        expect(hearing.time.central_office_time).to eq(expected_time)
        expect(LegacyHearing.first.time.central_office_time).to eq(expected_time)
      end
    end

    describe "#central_office_time_string" do
      it "changes to central office timezone (ET)" do
        expect(hearing.time.central_office_time_string).to eq("3:00 PM Eastern Time (US & Canada)")
        expect(LegacyHearing.first.time.central_office_time_string).to eq("3:00 PM Eastern Time (US & Canada)")
      end
    end

    context "hearing is virtual" do
      shared_examples_for "returns normalized timezone" do
        context "timezone is present" do
          before do
            virtual_hearing.hearing.appellant_recipient.update!(timezone: timezone)
            virtual_hearing.hearing.representative_recipient.update!(timezone: timezone)
          end

          it "changes to Appellant timezone (CT)" do
            expect(hearing.appellant_time).to eq(expected_time)
          end

          it "changes to Representative timezone (CT)" do
            expect(hearing.poa_time).to eq(expected_time)
          end
        end

        context "timezone is not present" do
          it "changes to local time (PT) for Appellant" do
            expect(hearing.appellant_time).to eq(expected_local)
          end

          it "changes to local time (PT) for Representative" do
            expect(hearing.poa_time).to eq(expected_local)
          end
        end

        context "timezone is invalid" do
          before do
            virtual_hearing.hearing.appellant_recipient.update!(timezone: invalid_tz)
            virtual_hearing.hearing.representative_recipient.update!(timezone: invalid_tz)
          end

          it "throws an ArgumentError for Appellant" do
            expect { hearing.appellant_time }.to raise_error ArgumentError
          end

          it "throws an ArgumentError for Representative" do
            expect { hearing.poa_time }.to raise_error ArgumentError
          end
        end
      end

      let(:timezone) { "America/Chicago" }
      let(:invalid_tz) { "123" }
      let(:expected_local) { Time.use_zone("America/Los_Angeles") { Time.zone.now.change(hour: 12, min: 0) } }
      let(:expected_time) { Time.use_zone(timezone) { Time.zone.now.change(hour: 14, min: 0) } }

      describe "hearing" do
        let!(:virtual_hearing) do
          create(
            :virtual_hearing,
            hearing: hearing
          )
        end

        before do
          hearing.reload
        end

        it_behaves_like "returns normalized timezone"
      end

      describe "legacy hearing" do
        include_context "legacy_hearing"

        let!(:virtual_hearing) do
          create(
            :virtual_hearing,
            hearing: hearing
          )
        end

        before do
          hearing.reload
        end

        it_behaves_like "returns normalized timezone"
      end
    end
  end

  context "with a legacy hearing scheduled for 08:30am" do
    describe "#local_time" do
      it "returns the right time when scheduled_in_timezone value is non-nil", tz: "UTC" do
        vacols_hearing = create(
          :case_hearing,
          hearing_type: HearingDay::REQUEST_TYPES[:central],
          hearing_date: Time.use_zone("UTC") do
            Time.zone.now.change(hour: 8, min: 30).in_time_zone("America/New_York")
          end
        )
        legacy_hearing = create(
          :legacy_hearing,
          regional_office: "C",
          vacols_record: vacols_hearing,
          vacols_id: vacols_hearing.hearing_pkseq.to_s,
          scheduled_in_timezone: "America/New_York"
        )

        expected_time = Time.use_zone("America/New_York") do
          Time.zone.now.change(
            year: legacy_hearing.scheduled_for.year,
            month: legacy_hearing.scheduled_for.month,
            day: legacy_hearing.scheduled_for.day,
            hour: 8,
            min: 30
          )
        end

        expect(legacy_hearing.time.local_time) == expected_time
      end
    end
  end

  context "#process_legacy_scheduled_time_string" do
    include_context "legacy_hearing"

    subject do
      HearingTimeService.new(hearing: legacy_hearing).process_legacy_scheduled_time_string(
        date: test_date,
        time_string: test_time_string
      )
    end

    context "When date is nil and time_string is nil" do
      let(:test_date) { nil }
      let(:test_time_string) { nil }

      it { is_expected.to be nil }
    end

    context "When date is non-nil and time_string is nil" do
      let(:test_date) { legacy_hearing.hearing_day.scheduled_for }
      let(:test_time_string) { nil }

      it { is_expected.to be nil }
    end

    context "When date is nil and time_string is non-nil" do
      let(:test_date) { nil }
      let(:test_time_string) { "2:00 PM Pacific Time (US & Canada)" }

      it { is_expected.to be nil }
    end

    context "When date is non-nil and time_string is non-nil" do
      let(:test_date) { "2024-09-01" }
      let(:test_time_string) { "2:00 PM Eastern Time (US & Canada)" }
      let(:expected_time) { Time.use_zone("UTC") { Time.zone.parse("#{test_date} 14:00") } }

      it { is_expected.to eq expected_time }
    end

    describe "When the time_string is Pacific Time" do
      let(:test_time_string) { "10:00 AM Pacific Time (US & Canada)" }
      let(:expected_time) { Time.use_zone("UTC") { Time.zone.parse("#{test_date} 10:00") } }

      context "Standard Time" do
        let(:test_date) { "2024-11-25" }

        it { is_expected.to eq expected_time }
      end

      context "DST" do
        let(:test_date) { "2024-08-25" }

        it { is_expected.to eq expected_time }
      end
    end

    describe "When the time_string is Eastern Time" do
      let(:test_time_string) { "9:00 AM Eastern Time (US & Canada)" }
      let(:expected_time) { Time.use_zone("UTC") { Time.zone.parse("#{test_date} 9:00") } }

      context "Standard Time" do
        let(:test_date) { "2024-12-01" }

        it { is_expected.to eq expected_time }
      end

      context "DST" do
        let(:test_date) { "2024-06-01" }

        it { is_expected.to eq expected_time }
      end
    end

    describe "When the time_string is Phillipine Standard Time" do
      let(:test_time_string) { "12:00 PM Philippine Standard Time" }
      let(:expected_time) { Time.use_zone("UTC") { Time.zone.parse("#{test_date} 12:00") } }

      # The Phillipines does not observe DST.
      context "Standard Time" do
        let(:test_date) { "2024-01-01" }

        it { is_expected.to eq expected_time }
      end
    end
  end
end
