describe SchedulePeriod do
  let(:schedule_period) { create(:ro_schedule_period) }

  context "spreadsheet" do
    before do
      S3Service.store_file(schedule_period.file_name, "spec/support/validRoSpreadsheet.xlsx", :filepath)
    end

    subject { schedule_period.spreadsheet }

    it { is_expected.to be_a(Roo::Excelx) }
  end
end
