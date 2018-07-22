describe SchedulePeriod do
  let(:schedule_period) do
    create(:ro_schedule_period, start_date: Date.parse("2019-04-01"),
                                end_date: Date.parse("2019-09-30"))
  end

  let(:allocation) do
    create(:allocation, regional_office: "RO17", allocated_days: 118, schedule_period: schedule_period)
  end

  before do
    get_unique_dates_for_ro_between("RO17", schedule_period, 35)
    get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 20).map do |date|
      create(:co_non_availability, date: date, schedule_period_id: schedule_period.id)
    end
  end

  context "spreadsheet" do
    subject { schedule_period.spreadsheet }

    it { is_expected.to be_a(Roo::Excelx) }
  end

  context "generate hearing schedule" do
    before do
      allocation
    end

    it do
      expect(schedule_period.ro_hearing_day_allocations.count).to eq(allocation.allocated_days)
      expect(schedule_period.ro_hearing_day_allocations[0].key?(:hearing_type)).to be_truthy
      expect(schedule_period.ro_hearing_day_allocations[0].key?(:hearing_date)).to be_truthy
      expect(schedule_period.ro_hearing_day_allocations[0].key?(:room_info)).to be_truthy
      expect(schedule_period.ro_hearing_day_allocations[0].key?(:regional_office)).to be_truthy
    end
  end
end
