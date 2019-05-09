# frozen_string_literal: true

describe HearingTimeService do
  Time.zone = "UTC"

  context "with a legacy hearing and a hearing scheduled for 12:00pm PT" do
    let!(:hearing) { create(:hearing, regional_office: "RO43", scheduled_time: "12:00") }
    let!(:legacy_hearing) do
      # legacy scheduled_for is incorrectly offset to central_office but reflects local time
      create(
        :legacy_hearing,
        regional_office: "RO43",
        scheduled_for: Time.use_zone("America/New_York") { Time.zone.now.change(hour: 12, min: 0) }
      )
    end

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
        offset = HearingTimeService.timezone_to_offset("America/New_York")
        expected_params = { scheduled_for: legacy_hearing.scheduled_for.change(hour: 13, min: 30, offset: offset) }
        expect(HearingTimeService.build_legacy_params_with_time(legacy_hearing, params)).to eq(expected_params)
        expect(params).to eq(scheduled_time_string: "13:30")
      end
    end

    describe "#local_time" do
      it "returns time object encoded in local time" do
        expected_time = Time.use_zone("America/Los_Angeles") { Time.zone.now.change(hour: 12, min: 0) }
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
  end
end
