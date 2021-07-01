# frozen_string_literal: true

describe JudgeSchedulePeriod, :all_dbs do
  let(:judge_schedule_period) { create(:judge_schedule_period) }
  let(:single_nonavail_date_judge_schedule_period) { create(:single_nonavail_date_judge_schedule_period) }
  let(:two_in_july_judge_schedule_period) { create(:two_in_july_judge_schedule_period) }
  let(:one_month_judge_schedule_period) { create(:one_month_judge_schedule_period) }
  let(:one_month_two_judge_schedule_period) { create(:one_month_two_judge_schedule_period) }
  let(:one_month_many_noavail_judge_schedule_period) { create(:one_month_many_noavail_judge_schedule_period) }
  let(:one_week_one_judge_schedule_period) { create(:one_week_one_judge_schedule_period) }
  let(:one_week_two_judge_schedule_period) { create(:one_week_two_judge_schedule_period) }

  context "validate_spreadsheet" do
    subject { judge_schedule_period.validate_spreadsheet }

    it { is_expected.to be_truthy }
  end

  context "assign judges to hearing days" do
    let!(:hearing_days) do
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             scheduled_for: Date.new(2018, 8, 14),
             regional_office: "RO13")
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             scheduled_for: Date.new(2018, 9, 12),
             regional_office: "RO13")
      create(:hearing_day,
             request_type: HearingDay::REQUEST_TYPES[:video],
             scheduled_for: Date.new(2018, 6, 2),
             regional_office: "RO13")
    end

    subject { judge_schedule_period.algorithm_assignments }
    it "verifying the algorithm output" do
      expect(subject.count).to eq(3)
      expect(subject[0].id).to be_truthy
      expect(subject[0].request_type).to be_truthy
      expect(subject[0].scheduled_for).to be_truthy
      expect(subject[0].regional_office).to be_truthy
      expect(subject[0].judge_id).to be_truthy
      expect(subject[0].judge.full_name).to be_truthy
    end
  end

  context "Judges are not assigned hearings on their non-availability days" do
    let!(:hearing_days) do
      get_every_nth_date_between(single_nonavail_date_judge_schedule_period.start_date,
                                 single_nonavail_date_judge_schedule_period.end_date, 4).map do |date|
        create(:hearing_day,
               request_type: HearingDay::REQUEST_TYPES[:video],
               scheduled_for: date, regional_office: "RO13")
      end
    end

    it "verifies judge algo cannot assign judge to this one week period" do
      expect do
        single_nonavail_date_judge_schedule_period.algorithm_assignments
      end.to raise_error(HearingSchedule::Errors::CannotAssignJudges)
    end

    subject { two_in_july_judge_schedule_period.algorithm_assignments }
    it "evenly splits the week between two judges" do
      expect(subject.count).to eq(hearing_days.count)
      judge_860 = subject.reduce(0) do |sum, hearing_day|
        sum += 1 unless hearing_day.judge_id != 860
        sum
      end
      judge_861 = subject.reduce(0) do |sum, hearing_day|
        sum += 1 unless hearing_day.judge_id != 861
        sum
      end
      not_july_31 = false
      subject.each do |hearing_day|
        hearing_day[:hearing_date] == Date.new(2018, 7, 31) && hearing_day.judge_id == 860
      end
      expect(not_july_31).to be_falsey
      expect(judge_860 + judge_861).to eq(hearing_days.count)
    end
  end

  context " judges are not assigned hearings on their travel board days, the week before, or the week after" do
    let!(:travel_board) do
      create(:july_travel_board_schedule)
    end
    let!(:hearing_days) do
      get_every_nth_date_between(one_month_judge_schedule_period.start_date,
                                 one_month_judge_schedule_period.end_date, 4).map do |date|
        create(:hearing_day,
               request_type: HearingDay::REQUEST_TYPES[:video],
               scheduled_for: date,
               regional_office: "RO13")
      end
    end

    it "verifies judge algo cannot assign judge to week prior or after assigned TB week" do
      expect do
        one_month_judge_schedule_period.algorithm_assignments
      end.to raise_error(HearingSchedule::Errors::CannotAssignJudges)
    end

    subject { one_month_two_judge_schedule_period.algorithm_assignments }
    it "verify period is covered by both judges" do
      expect(subject.count).to eq(hearing_days.count)
      judge_860 = subject.reduce(0) do |sum, hearing_day|
        sum += 1 unless hearing_day.judge_id != 860
        sum
      end
      judge_861 = subject.reduce(0) do |sum, hearing_day|
        sum += 1 unless hearing_day.judge_id != 861
        sum
      end
      expect(judge_860).to eq(3)
      expect(judge_861).to eq(3)
      expect(judge_860 + judge_861).to eq(hearing_days.count)
    end
  end

  context "A judge with a lot of non-availability days still gets as many hearings as possible" do
    let!(:hearing_days) do
      [
        create(:hearing_day,
               request_type: HearingDay::REQUEST_TYPES[:video],
               scheduled_for: DateTime.new(2018, 7, 22, 9, 0, 0, "+0"),
               regional_office: "RO13"),
        create(:hearing_day,
               request_type: HearingDay::REQUEST_TYPES[:video],
               scheduled_for: DateTime.new(2018, 7, 29, 9, 0, 0, "+0"),
               regional_office: "RO13"),
        create(:hearing_day,
               request_type: HearingDay::REQUEST_TYPES[:video],
               scheduled_for: DateTime.new(2018, 8, 1, 9, 0, 0, "+0"),
               regional_office: "RO13"),
        create(:hearing_day,
               request_type: HearingDay::REQUEST_TYPES[:video],
               scheduled_for: DateTime.new(2018, 8, 6, 9, 0, 0, "+0"),
               regional_office: "RO13"),
        create(:hearing_day,
               request_type: HearingDay::REQUEST_TYPES[:video],
               scheduled_for: DateTime.new(2018, 8, 13, 9, 0, 0, "+0"),
               regional_office: "RO13"),
        create(:hearing_day,
               request_type: HearingDay::REQUEST_TYPES[:video],
               scheduled_for: DateTime.new(2018, 8, 17, 9, 0, 0, "+0"),
               regional_office: "RO13")
      ]
    end

    subject { one_month_many_noavail_judge_schedule_period.algorithm_assignments }
    it "evenly splits the week between two judges" do
      expect(subject.count).to eq(hearing_days.count)
      judge_860 = subject.reduce(0) do |sum, hearing_day|
        sum += 1 unless hearing_day.judge_id != 860
        sum
      end
      judge_861 = subject.reduce(0) do |sum, hearing_day|
        sum += 1 unless hearing_day.judge_id != 861
        sum
      end
      expect(judge_860).to eq(2)
      expect(judge_861).to eq(4)
      expect(judge_860 + judge_861).to eq(hearing_days.count)
    end
  end

  context "Judges cannot be assigned multiple hearing days on the same day" do
    let!(:hearing_days) do
      get_every_nth_date_between(one_week_one_judge_schedule_period.start_date,
                                 one_week_one_judge_schedule_period.end_date, 4).map do |date|
        create(:hearing_day,
               request_type: HearingDay::REQUEST_TYPES[:video],
               scheduled_for: date,
               regional_office: "RO13")
        create(:hearing_day,
               request_type: HearingDay::REQUEST_TYPES[:video],
               scheduled_for: date,
               regional_office: "RO17")
      end
    end

    it "verifies judge algo cannot assign judge to multiple hearing days" do
      expect do
        one_week_one_judge_schedule_period.algorithm_assignments
      end.to raise_error(HearingSchedule::Errors::CannotAssignJudges)
    end

    subject { one_week_two_judge_schedule_period.algorithm_assignments }
    it "evenly splits the rooms between two judges" do
      expect(subject.count).to eq(4)
      # two rooms
      expect(subject.count).to eq(hearing_days.count * 2)
      judge_860 = subject.reduce(0) do |sum, hearing_day|
        sum += 1 unless hearing_day.judge_id != 860
        sum
      end
      judge_861 = subject.reduce(0) do |sum, hearing_day|
        sum += 1 unless hearing_day.judge_id != 861
        sum
      end
      expect(judge_860).to eq(2)
      expect(judge_861).to eq(2)
      expect(judge_860 + judge_861).to eq(hearing_days.count * 2)
    end
  end
end
