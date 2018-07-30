describe JudgeSchedulePeriod do
  let(:judge_schedule_period) { create(:judge_schedule_period) }

  let(:hearing_days) do
    get_dates_between(judge_schedule_period.start_date, judge_schedule_period.end_date, 3).map do |date|
      case_hearing = create(:case_hearing, hearing_type: "C", hearing_date: date, folder_nr: "VIDEO RO13")
    end
  end

  context "validate_spreadsheet" do
    subject { judge_schedule_period.validate_spreadsheet }

    it { is_expected.to be_truthy }
  end


  context "assign judges to hearing days" do
    before do
      hearing_days
    end

    subject { judge_schedule_period.algorithm_assignments }
    it "verifying the algorithm output" do
      expect(subject[0].key?(:hearing_type)).to be_truthy
      expect(subject[0].key?(:hearing_date)).to be_truthy
      expect(subject[0].key?(:room_info)).to be_truthy
      expect(subject[0].key?(:regional_office)).to be_truthy
      expect(subject[0].key?(:judge_id)).to be_truthy
      expect(subject[0].key?(:judge_name)).to be_truthy
    end
  end
end
