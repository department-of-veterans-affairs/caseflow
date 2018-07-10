describe RoNonAvailability do
  let(:ro_schedule_period) { create(:ro_schedule_period) }

  context ".import_ro_non_availability" do
    before do
      S3Service.store_file(ro_schedule_period.file_name, "spec/support/validRoSpreadsheet.xlsx", :filepath)
    end

    it "imports ro non-availability days" do
      expect(RoNonAvailability.where(schedule_period: ro_schedule_period).count).to eq(0)
      RoNonAvailability.import_ro_non_availability(ro_schedule_period)
      expect(RoNonAvailability.where(schedule_period: ro_schedule_period).count).to eq(228)
    end
  end
end
