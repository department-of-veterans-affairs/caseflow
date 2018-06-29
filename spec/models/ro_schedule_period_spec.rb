describe RoSchedulePeriod do
  let(:ro_schedule_period) { create(:ro_schedule_period) }

  context "validate_spreadsheet" do
    before do
      S3Service.store_file(ro_schedule_period.file_name, "spec/support/validRoSpreadsheet.xlsx", :filepath)
    end

    subject { ro_schedule_period.validate_spreadsheet }

    it { is_expected.to be_truthy }
  end
end
