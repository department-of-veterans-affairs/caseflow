describe CoNonAvailability do
  let(:ro_schedule_period) { create(:ro_schedule_period) }

  context ".import_co_non_availability" do
    before do
      S3Service.store_file(ro_schedule_period.file_name, "spec/support/validRoSpreadsheet.xlsx", :filepath)
    end

    it "imports co non-availability days" do
      expect(CoNonAvailability.where(schedule_period: ro_schedule_period).count).to eq(0)
      CoNonAvailability.import_co_non_availability(ro_schedule_period)
      expect(CoNonAvailability.where(schedule_period: ro_schedule_period).count).to eq(4)
    end
  end
end
