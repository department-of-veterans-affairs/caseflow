describe RoSchedulePeriod do
  let(:ro_schedule_period) { create(:ro_schedule_period) }

  context "validate_spreadsheet" do
    subject { ro_schedule_period.validate_spreadsheet }

    it { is_expected.to be_truthy }
  end
end
