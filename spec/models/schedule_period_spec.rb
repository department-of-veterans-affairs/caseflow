# frozen_string_literal: true

describe SchedulePeriod, :postgres do
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
      total_allocation_days = HearingSchedule::GenerateHearingDaysSchedule.new(schedule_period)
        .generate_co_hearing_days_schedule.size +
                              Allocation.where(schedule_period: schedule_period).sum(:allocated_days) +
                              Allocation.where(schedule_period: schedule_period).sum(:allocated_days_without_room)
      assignments = schedule_period.algorithm_assignments

      expect(assignments.count).to eq(total_allocation_days)
      expect(assignments[0].key?(:request_type)).to be_truthy
      expect(assignments[0].key?(:scheduled_for)).to be_truthy
      expect(assignments[0].key?(:room)).to be_truthy
      expect(assignments[0].key?(:regional_office)).to be_truthy if assignments[0][:request_type] ==
                                                                    HearingDay::REQUEST_TYPES[:video]
    end
  end
end
