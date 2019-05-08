# frozen_string_literal: true

describe HearingTimeService do
  describe "#build_params_with_time" do
    let!(:hearing) { create(:hearing, scheduled_time: "12:00") }
    let!(:legacy_hearing) { create(:legacy_hearing, scheduled_for: Time.now.utc.change(hour: 12, min: 0)) }
    let!(:params) do
      { scheduled_time_string: "13:30" }
    end

    it "returns scheduled_time string parameter and removes scheduled_time_string param" do
      expect(HearingTimeService.build_params_with_time(hearing, params)).to eq(scheduled_time: "13:30")
      expect(params).to eq(scheduled_time_string: "13:30")
    end
  end

  describe "#build_legacy_params_with_time" do
    let!(:hearing) { create(:hearing, scheduled_time: "12:00") }
    let!(:legacy_hearing) { create(:legacy_hearing, scheduled_for: Time.now.utc.change(hour: 12, min: 0)) }
    let(:params) do
      { scheduled_time_string: "13:30" }
    end

    it "returns scheduled_time string parameter and removes scheduled_time_string param" do
      expected_params = { scheduled_for: legacy_hearing.scheduled_for.change(hour: 13, min: 30) }
      expect(HearingTimeService.build_legacy_params_with_time(legacy_hearing, params)).to eq(expected_params)
      expect(params).to eq(scheduled_time_string: "13:30")
    end
  end

  describe "#to_s" do
    let!(:hearing) { create(:hearing, scheduled_time: "12:00") }
    let!(:legacy_hearing) { create(:legacy_hearing, scheduled_for: Time.now.utc.change(hour: 12, min: 0)) }

    it "builds string with time" do
      expect(legacy_hearing.time.to_s).to eq("12:00")
      expect(hearing.time.to_s).to eq("12:00")
    end
  end

  describe "#central_office_time" do
    context "for hearings in PT" do
      let!(:hearing) { create(:hearing, regional_office: "RO43", scheduled_time: "12:00") }
      let!(:legacy_hearing) do
        create(:legacy_hearing, regional_office: "RO43", scheduled_for: Time.now.utc.change(hour: 12, min: 0))
      end

      it "changes to central office timezone (ET)" do
        expect(hearing.time.central_office_time).to eq("15:00")
        expect(legacy_hearing.time.central_office_time).to eq("15:00")
      end
    end
  end

  describe "#to_datetime" do
    let!(:legacy_hearing) { create(:legacy_hearing, scheduled_for: Time.now.utc.change(hour: 12, min: 0)) }

    it "converts legacy hearings to format consistent with hearings scheduled_time column" do
      expect(legacy_hearing.time.to_datetime.iso8601).to eq("2000-01-01T12:00:00Z")
    end
  end
end
