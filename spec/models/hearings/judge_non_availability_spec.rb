# frozen_string_literal: true

describe JudgeNonAvailability, :all_dbs do
  let(:judge_schedule_period) { create(:judge_schedule_period) }

  context ".import_judge_non_availability" do
    it "imports judge non-availability days" do
      expect(JudgeNonAvailability.where(schedule_period: judge_schedule_period).count).to eq(3)
      expect(JudgeNonAvailability.where(
        schedule_period: judge_schedule_period,
        date: nil
      ).count).to eq(1)
    end
  end
end
