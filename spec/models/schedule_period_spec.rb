describe SchedulePeriod do
  let!(:schedule_period) { create(:ro_schedule_period) }

  context "spreadsheet" do
    subject { schedule_period.spreadsheet }

    it { is_expected.to be_a(Roo::Excelx) }
  end

  context "validation" do
    before do
      schedule_period.update!(finalized: true)
    end

    subject { create(:ro_schedule_period) }

    it "returns an error" do
      expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context "generate hearing schedule" do
    it do
      total_allocation_days = Allocation.where(schedule_period: schedule_period).sum(:allocated_days)
      assignments = schedule_period.algorithm_assignments

      expect(assignments.count).to eq(total_allocation_days)
      expect(assignments[0].key?(:hearing_type)).to be_truthy
      expect(assignments[0].key?(:hearing_date)).to be_truthy
      expect(assignments[0].key?(:room)).to be_truthy
      expect(assignments[0].key?(:regional_office)).to be_truthy
    end
  end
end
