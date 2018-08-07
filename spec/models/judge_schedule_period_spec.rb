describe JudgeSchedulePeriod do
  let(:judge_schedule_period) { create(:judge_schedule_period) }
  let(:single_nonavail_date_judge_schedule_period) { create(:single_nonavail_date_judge_schedule_period) }
  let(:two_in_july_judge_schedule_period) { create(:two_in_july_judge_schedule_period) }

  context "validate_spreadsheet" do
    subject { judge_schedule_period.validate_spreadsheet }

    it { is_expected.to be_truthy }
  end

  context "assign judges to hearing days" do
    let!(:hearing_days) do
      get_dates_between(judge_schedule_period.start_date, judge_schedule_period.end_date, 3).map do |date|
        create(:case_hearing, hearing_type: "C", hearing_date: date, folder_nr: "VIDEO RO13")
      end
    end

    subject { judge_schedule_period.algorithm_assignments }
    it "verifying the algorithm output" do
      expect(subject.count).to eq(hearing_days.count)
      expect(subject[0].key?(:hearing_pkseq)).to be_truthy
      expect(subject[0].key?(:hearing_type)).to be_truthy
      expect(subject[0].key?(:hearing_date)).to be_truthy
      expect(subject[0].key?(:room_info)).to be_truthy
      expect(subject[0].key?(:regional_office)).to be_truthy
      expect(subject[0].key?(:judge_id)).to be_truthy
      expect(subject[0].key?(:judge_name)).to be_truthy
    end
  end

  context "Judges are not assigned hearings on their non-availability days", focus: true do
    let!(:hearing_days) do
      get_dates_between(single_nonavail_date_judge_schedule_period.start_date,
                        single_nonavail_date_judge_schedule_period.end_date, 5).map do |date|
        create(:case_hearing, hearing_type: "C", hearing_date: date, folder_nr: "VIDEO RO13", room: 4)
      end
    end

    it "verifies judge algo cannot assign judge to this one week period" do
      expect {
        single_nonavail_date_judge_schedule_period.algorithm_assignments
      }.to raise_error(HearingSchedule::AssignJudgesToHearingDays::CannotAssignJudges)
    end

    subject { two_in_july_judge_schedule_period.algorithm_assignments }
    it "evenly splits the week between two judges" do
      expect(subject.count).to eq(hearing_days.count)
    end
  end
end
