describe SchedulePeriod do
  let(:schedule_period) do
    create(:ro_schedule_period, start_date: Date.parse("2019-04-01"),
                                end_date: Date.parse("2019-09-30"))
  end

  context "spreadsheet" do
    subject { schedule_period.spreadsheet }

    it { is_expected.to be_a(Roo::Excelx) }
  end

  context "generate hearing schedule" do
    it do
      total_allocation_days = Allocation.where(schedule_period: schedule_period).sum(:allocated_days)
      expect(schedule_period.ro_hearing_day_allocations.count).to eq(total_allocation_days)
      expect(schedule_period.ro_hearing_day_allocations[0].key?(:hearing_type)).to be_truthy
      expect(schedule_period.ro_hearing_day_allocations[0].key?(:hearing_date)).to be_truthy
      expect(schedule_period.ro_hearing_day_allocations[0].key?(:room_info)).to be_truthy
      expect(schedule_period.ro_hearing_day_allocations[0].key?(:regional_office)).to be_truthy
    end
  end
end
