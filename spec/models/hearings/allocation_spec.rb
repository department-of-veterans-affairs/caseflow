describe Allocation do
  let(:ro_schedule_period) { create(:ro_schedule_period) }

  context ".import_allocation" do
    before do
      S3Service.store_file(ro_schedule_period.file_name, "spec/support/validRoSpreadsheet.xlsx", :filepath)
    end

    it "imports allocations" do
      expect(Allocation.where(schedule_period: ro_schedule_period).count).to eq(0)
      Allocation.import_allocation(ro_schedule_period)
      expect(Allocation.where(schedule_period: ro_schedule_period).count).to eq(57)
    end
  end
end
