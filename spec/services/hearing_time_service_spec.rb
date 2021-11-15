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

    let!(:hearing) { create(:hearing, regional_office: "RO43", scheduled_time: "12:00") }

    describe "#build_params_with_time" do
      let!(:params) do
        { scheduled_time_string: "13:30" }
      end

      it "returns scheduled_time string parameter and removes scheduled_time_string param" do
        expect(HearingTimeService.build_params_with_time(hearing, params)).to eq(scheduled_time: "13:30")
        expect(params).to eq(scheduled_time_string: "13:30")
      end
    end

    describe "#build_legacy_params_with_time" do
      let(:params) do
        { scheduled_time_string: "13:30" }
      end

      it "returns scheduled_for parameter in ET and removes scheduled_time_string param" do
        expected_scheduled_for = Time.use_zone("America/New_York") do
          time = legacy_hearing.scheduled_for.to_datetime
          Time.zone.local(time.year, time.month, time.day, 13, 30)
        end
        expected_params = { scheduled_for: expected_scheduled_for }
        expect(HearingTimeService.build_legacy_params_with_time(legacy_hearing, params)).to eq(expected_params)
        expect(params).to eq(scheduled_time_string: "13:30")
      end
    end

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
        expect(LegacyHearing.first.time.scheduled_time_string).to eq("12:00")
        expect(hearing.time.scheduled_time_string).to eq("12:00")
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
        expect(hearing.time.central_office_time_string).to eq("15:00")
        expect(LegacyHearing.first.time.central_office_time_string).to eq("15:00")
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
            expect(hearing.time.appellant_time).to eq(expected_time)
          end

          it "changes to Representative timezone (CT)" do
            expect(hearing.time.poa_time).to eq(expected_time)
          end
        end

        context "timezone is not present" do
          it "changes to local time (PT) for Appellant" do
            expect(hearing.time.appellant_time).to eq(expected_local)
          end

          it "changes to local time (PT) for Representative" do
            expect(hearing.time.poa_time).to eq(expected_local)
          end
        end

        context "timezone is invalid" do
          before do
            virtual_hearing.hearing.appellant_recipient.update!(timezone: invalid_tz)
            virtual_hearing.hearing.representative_recipient.update!(timezone: invalid_tz)
          end

          it "throws an ArgumentError for Appellant" do
            expect { hearing.time.appellant_time }.to raise_error ArgumentError
          end

          it "throws an ArgumentError for Representative" do
            expect { hearing.time.poa_time }.to raise_error ArgumentError
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
end
