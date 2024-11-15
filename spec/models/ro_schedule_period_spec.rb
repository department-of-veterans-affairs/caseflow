# frozen_string_literal: true

describe RoSchedulePeriod, :postgres do
  let(:ro_schedule_period) { create(:ro_schedule_period) }

  context "validate_spreadsheet" do
    subject { ro_schedule_period.validate_spreadsheet }

    it { is_expected.to be_truthy }

    context "when spreadsheet is invalid" do
      let(:spreadsheet_errors) do
        [
          HearingSchedule::ValidateRoSpreadsheet::RoDatesNotUnique.new("RoDatesNotUnique message"),
          HearingSchedule::ValidateRoSpreadsheet::RoDatesNotInRange.new("RoDatesNotInRange message"),
          HearingSchedule::ValidateRoSpreadsheet::RoDatesNotCorrectFormat.new("RoDatesNotCorrectFormat message"),
          HearingSchedule::ValidateRoSpreadsheet::RoTemplateNotFollowed.new("RoTemplateNotFollowed message")
        ]
      end

      before do
        allow_any_instance_of(HearingSchedule::ValidateRoSpreadsheet).to receive(:validate) { spreadsheet_errors }
      end

      it "adds errors to model" do
        model = build(:ro_schedule_period)
        model.valid?
        expect(model).to_not be_valid
        expect(model.errors[:base]).to match_array([spreadsheet_errors])
      end
    end
  end

  context "Allocate RO Days Per Given Schedule" do
    subject { ro_schedule_period.algorithm_assignments }

    it "create schedule" do
      is_expected.to be_truthy
    end
  end
end
