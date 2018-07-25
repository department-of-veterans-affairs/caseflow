describe HearingSchedule::AssignJudgesToHearingDays do

  let(:schedule_period) do
    create(:ro_schedule_period, start_date: Date.parse("2018-04-01"),
                                end_date: Date.parse("2018-09-30"))
  end

  let(:assign_judges_to_hearing_days) do
    HearingSchedule::AssignJudgesToHearingDays.new(schedule_period)
  end

  context "assign judges info from VACOLS staff and Caseflow" do
    
    subject { assign_judges_to_hearing_days }

    context "when Judge exists in both VACOLS and Caseflow" do
      before do
        3.times do
          judge = FactoryBot.create(:user)
          create(:staff, :hearing_judge, sdomainid: judge.css_id)
        end
      end

      it "Caseflow user and staff information are populated" do      
        expect(subject.judges.count).to eq(3)
        subject.judges.keys.each do |css_id|
          expect(subject.judges[css_id][:staff_info].sdomainid).to eq(css_id)
          expect(subject.judges[css_id][:user_info].css_id).to eq(css_id)
        end
      end
    end

    context "when judge exists in VACOLS but not caseflow" do
      before do
        3.times do |i|
          create(:staff, :hearing_judge, sdomainid: "CSS_ID_#{i}")
        end
      end

      it "staff info is populate but user info is nil" do
        expect(subject.judges.count).to eq(3)
        subject.judges.keys.each do |css_id|
          expect(subject.judges[css_id][:staff_info].sdomainid).to eq(css_id)
          expect(subject.judges[css_id][:user_info]).to eq(nil)
        end
      end
    end
  end

  context "assigning non-available days to judges" do
    before do
      @num_non_available_days = [10, 5, 15]
      @num_non_available_days.count.times do |i|
        judge = FactoryBot.create(:user)
        get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, @num_non_available_days[i]).map do |date|
          create(:judge_non_availability, object_identifier: judge.css_id, date: date, schedule_period_id: schedule_period.id)
        end
        create(:staff, :hearing_judge, sdomainid: judge.css_id)
      end
    end

    let(:assign_judges_to_hearing_days) do
      HearingSchedule::AssignJudgesToHearingDays.new(schedule_period)
    end

    subject { assign_judges_to_hearing_days }

    it "assigns non availabilities to judges" do
      expect(subject.judges.count).to eq(3)
      subject.judges.keys.each_with_index do |css_id, index|
        expect(subject.judges[css_id][:non_availabilities].count).to eq(@num_non_available_days[index])  
      end
    end
  end

  context "handle travel board hearings" do
    let(:member1) { create(:staff, :hearing_judge) }
    let(:member2) { create(:staff, :hearing_judge) }
    let(:member3) { create(:staff, :hearing_judge) }

    let(:tb_hearing) do
      create(:travel_board_schedule, tbro: "RO17",
        tbstdate: Date.parse("2018-06-04"), tbenddate: Date.parse("2018-06-08"),
        tbmem1: member1.sattyid,
        tbmem2: member2.sattyid,
        tbmem3: member3.sattyid
      )
    end

    let(:tb_hearing2) do
      create(:travel_board_schedule, tbro: "RO17",
        tbstdate: Date.parse("2018-09-03"), tbenddate: Date.parse("2018-09-07"),
        tbmem1: member1.sattyid,
        tbmem2: member2.sattyid,
        tbmem3: member3.sattyid
      )
    end

    subject { assign_judges_to_hearing_days }

    it "judges are given non-availabilities based on travel board" do
      start_date = 3.business_days.before(tb_hearing[:tbstdate])
      end_date = 3.business_days.after(tb_hearing[:tbenddate])

      start_date2 = 3.business_days.before(tb_hearing2[:tbstdate])
      end_date2 = 3.business_days.after(tb_hearing2[:tbenddate])

      subject.judges do |css_id, judge|
        expect(judge[:non_availabilities].include?(start_date)).to be_truthy
        expect(judge[:non_availabilities].include?(end_date)).to be_truthy

        expect(judge[:non_availabilities].include?(start_date2)).to be_truthy
        expect(judge[:non_availabilities].include?(end_date2)).to be_truthy
        expect(judge[:non_availabilities].count).to eq(22)
      end
    end
  end

  context "handle VIDEO hearings" do
    before do
      @judges = []
      video_hearing_days

      5.times do
        judge = FactoryBot.create(:user)
        @judges << create(:staff, :hearing_judge, sdomainid: judge.css_id)
      end
    end

    let(:video_hearing_days) do
      get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 10).map do |date|
        create(:case_hearing, hearing_type: "C", hearing_date: date, folder_nr: "VIDEO RO13")
      end
    end

    subject { assign_judges_to_hearing_days.match_hearing_days_to_judges }

    it "allocates VIDEO hearing days to judges" do
      # binding.pry
      expect(subject.count).to eq(video_hearing_days.count)
      judge_ids = subject.map { |hearing_day| hearing_day[:judge_id] }

      @judges.each do |judge|
        expect(judge_ids.count(judge.sattyid)).to eq(2)
      end
    end
  end

  context "handle co hearings" do
    before do
      co_hearing_days
    end

    let(:co_hearing_days) do
      get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 50).map do |date|
        create(:case_hearing, hearing_type: "C", hearing_date: date, folder_nr: nil)
      end
    end

    subject { assign_judges_to_hearing_days.video_co_hearing_days }

    it "filter CO non wednesdays" do
      subject.each do |hearing_day|
        expect(hearing_day.hearing_date.wednesday?).to be(true)
      end
    end
  end

  context "handle CO hearings" do
    before do
      co_hearing_days
    end

    let(:co_hearing_days) do
      get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 50).map do |date|
        create(:case_hearing, hearing_type: "C", hearing_date: date, folder_nr: nil)
      end
    end

    subject { assign_judges_to_hearing_days.video_co_hearing_days }

    it "filter CO non wednesdays" do
      subject.each do |hearing_day|
        expect(hearing_day.hearing_date.wednesday?).to be(true)
      end
    end
  end
end