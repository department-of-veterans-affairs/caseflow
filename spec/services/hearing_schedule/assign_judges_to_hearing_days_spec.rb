# frozen_string_literal: true

describe HearingSchedule::AssignJudgesToHearingDays, :all_dbs do
  let(:schedule_period) do
    create(:blank_judge_schedule_period, start_date: Date.parse("2018-04-01"),
                                         end_date: Date.parse("2018-07-31"))
  end

  let(:assign_judges_to_hearing_days) do
    HearingSchedule::AssignJudgesToHearingDays.new(schedule_period)
  end

  context "assign judges info from VACOLS staff and Caseflow" do
    before do
      create(:case_hearing,
             hearing_type: HearingDay::REQUEST_TYPES[:central],
             hearing_date: Date.new(2018, 7, 6),
             folder_nr: "VIDEO RO13")
    end
    subject { assign_judges_to_hearing_days }

    context "when Judge exists in both VACOLS and Caseflow" do
      before do
        3.times do
          judge = create(:user)
          create(:judge_non_availability, date: Date.new(2018, 7, 6), schedule_period_id: schedule_period.id,
                                          object_identifier: judge.css_id)
          create(:staff, :hearing_judge, sdomainid: judge.css_id)
        end
      end

      it "staff information is populated" do
        expect(subject.judges.count).to eq(3)
        subject.judges.each_key do |css_id|
          expect(subject.judges[css_id][:staff_info].sdomainid).to eq(css_id)
        end
      end
    end

    context "assigning non-available days to judges" do
      before do
        @num_non_available_days = [10, 5, 15, 0]
        @num_non_available_days.count.times do |i|
          judge = create(:user)
          get_unique_dates_between(schedule_period.start_date, schedule_period.end_date,
                                   @num_non_available_days[i]).map do |date|
            create(:judge_non_availability, object_identifier: judge.css_id,
                                            date: date, schedule_period_id: schedule_period.id)
          end
          create(:staff, :hearing_judge, sdomainid: judge.css_id)
        end

        # creating a judge and n/a with nil date.
        judge = create(:user)
        create(:judge_non_availability, object_identifier: judge.css_id,
                                        date: nil, schedule_period_id: schedule_period.id)
        create(:staff, :hearing_judge, sdomainid: judge.css_id)
      end

      let(:assign_judges_to_hearing_days) do
        HearingSchedule::AssignJudgesToHearingDays.new(schedule_period)
      end

      subject { assign_judges_to_hearing_days }

      it "assigns non availabilities to judges", skip: "Fails intermittently on circle" do
        expect(subject.judges.count).to eq(4)
        subject.judges.keys.each_with_index do |css_id, index|
          expect(subject.judges[css_id][:non_availabilities].count).to eq(@num_non_available_days[index])
        end
      end
    end

    context "travel board hearing day non-availabilities added" do
      before do
        non_availabilities
      end
      let(:member1) { create(:staff, :hearing_judge) }
      let(:member2) { create(:staff, :hearing_judge) }
      let(:member3) { create(:staff, :hearing_judge) }

      let(:tb_hearing) do
        create(:travel_board_schedule, tbro: "RO17",
                                       tbstdate: Date.parse("2018-06-04"), tbenddate: Date.parse("2018-06-08"),
                                       tbmem1: member1.sattyid,
                                       tbmem2: member2.sattyid,
                                       tbmem3: member3.sattyid)
      end

      let(:tb_hearing2) do
        create(:travel_board_schedule, tbro: "RO17",
                                       tbstdate: Date.parse("2018-05-07"), tbenddate: Date.parse("2018-05-11s"),
                                       tbmem1: member1.sattyid,
                                       tbmem2: member2.sattyid,
                                       tbmem3: member3.sattyid)
      end

      let(:non_availabilities) do
        date = get_unique_dates_between(schedule_period.start_date,
                                        schedule_period.end_date, 1).first
        create(:judge_non_availability, date: date, schedule_period_id: schedule_period.id,
                                        object_identifier: member1.sdomainid)
        create(:judge_non_availability, date: date + 1, schedule_period_id: schedule_period.id,
                                        object_identifier: member2.sdomainid)
        create(:judge_non_availability, date: date + 2, schedule_period_id: schedule_period.id,
                                        object_identifier: member3.sdomainid)
      end

      subject { assign_judges_to_hearing_days }

      it "judges are given non-availabilities based on travel board" do
        start_date = 3.business_days.before(tb_hearing[:tbstdate])
        end_date = 3.business_days.after(tb_hearing[:tbenddate])

        start_date2 = 3.business_days.before(tb_hearing2[:tbstdate])
        end_date2 = 3.business_days.after(tb_hearing2[:tbenddate])

        expect(subject.judges.count).to eq(3)
        subject.judges do |_css_id, judge|
          expect(judge[:non_availabilities]).to include start_date
          expect(judge[:non_availabilities]).to include end_date

          expect(judge[:non_availabilities]).to include start_date2
          expect(judge[:non_availabilities]).to include end_date2
          expect(judge[:non_availabilities].count).to eq(22)
        end
      end
    end
  end

  context "handle VIDEO hearings" do
    before do
      @judges = []

      5.times do
        judge = create(:user)
        date = get_unique_dates_between(schedule_period.start_date,
                                        schedule_period.end_date, 1).first
        create(:judge_non_availability, date: date, schedule_period_id: schedule_period.id,
                                        object_identifier: judge.css_id)
        @judges << create(:staff, :hearing_judge, sdomainid: judge.css_id)
      end
    end

    let!(:video_hearing_days) do
      get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 10).map do |date|
        create(:case_hearing,
               hearing_type: HearingDay::REQUEST_TYPES[:central],
               hearing_date: date,
               folder_nr: "VIDEO RO13")
      end
    end

    subject { assign_judges_to_hearing_days.match_hearing_days_to_judges }

    it "assign VIDEO hearing days to judges", skip: "Fails intermittently" do
      judge_ids = subject.map { |hearing_day| hearing_day[:judge_id] }

      @judges.each do |judge|
        expect(judge_ids.count(judge.sattyid)).to eq(2)
      end
    end
  end

  context "handle already assgined hearing day" do
    before do
      judge
      co_hearing_day
    end

    let(:judge) do
      judge = create(:user)
      @date = get_unique_dates_between(schedule_period.start_date,
                                       schedule_period.end_date, 1).first
      create(:judge_non_availability, date: @date, schedule_period_id: schedule_period.id,
                                      object_identifier: judge.css_id)
      create(:staff, :hearing_judge, sdomainid: judge.css_id)
    end

    let(:co_hearing_day) do
      create(:case_hearing,
             hearing_type: HearingDay::REQUEST_TYPES[:central],
             hearing_date: @date,
             folder_nr: "VIDEO RO13")
    end

    subject { assign_judges_to_hearing_days }

    it "expect judge to have non-available days", skip: "This test is flaky." do
      expect(subject.judges[judge.sdomainid][:non_availabilities]).to include co_hearing_day.hearing_date.to_date
    end
  end

  context "no Video and CO hearing days exist" do
    before do
      judge
    end

    let(:judge) do
      judge = create(:user)
      date = get_unique_dates_between(schedule_period.start_date,
                                      schedule_period.end_date, 1).first
      create(:judge_non_availability, date: date, schedule_period_id: schedule_period.id,
                                      object_identifier: judge.css_id)
      create(:staff, :hearing_judge, sdomainid: judge.css_id)
    end

    subject { assign_judges_to_hearing_days.match_hearing_days_to_judges }

    it do
      expect { subject }.to raise_error(HearingSchedule::AssignJudgesToHearingDays::HearingDaysNotAllocated)
    end
  end

  context "Allocating VIDEO and CO hearing days to judges evenly" do
    let(:hearing_days) do
      hearing_days = {}
      date_count = {}

      get_dates_between(schedule_period.start_date, schedule_period.end_date, 300).map do |date|
        date_count[date] ||= 0

        next if date_count[date] >= 1 && date.wednesday?

        case_hearing = create(:case_hearing,
                              hearing_type: HearingDay::REQUEST_TYPES[:central],
                              hearing_date: date,
                              folder_nr: "VIDEO RO13")
        hearing_days[case_hearing.hearing_pkseq] = case_hearing

        co_case_hearing = create(:case_hearing,
                                 hearing_type: HearingDay::REQUEST_TYPES[:central],
                                 hearing_date: date, folder_nr: nil)
        hearing_days[co_case_hearing.hearing_pkseq] = co_case_hearing
        date_count[date] += 1
      end
      hearing_days
    end

    subject { assign_judges_to_hearing_days }

    context "errors with judges cannot be assigned" do
      before do
        hearing_days
        2.times do
          judge = create(:user)
          get_unique_dates_between(schedule_period.start_date, schedule_period.end_date,
                                   80).map do |date|
            create(:judge_non_availability, date: date, schedule_period_id: schedule_period.id,
                                            object_identifier: judge.css_id)
          end
          create(:staff, :hearing_judge, sdomainid: judge.css_id)
        end
      end
      subject { assign_judges_to_hearing_days.match_hearing_days_to_judges }

      it do
        expect { subject }.to raise_error(HearingSchedule::Errors::CannotAssignJudges)
      end
    end

    context "allocated judges to hearing days" do
      before do
        hearing_days
        judges
        create(:travel_board_schedule, tbro: "RO13",
                                       tbstdate: Date.parse("2018-06-04"), tbenddate: Date.parse("2018-06-08"),
                                       tbmem1: judges[0].sattyid,
                                       tbmem2: judges[1].sattyid,
                                       tbmem3: judges[2].sattyid)

        create(:travel_board_schedule, tbro: "RO13",
                                       tbstdate: Date.parse("2018-04-16"), tbenddate: Date.parse("2018-04-20"),
                                       tbmem1: judges[3].sattyid,
                                       tbmem2: judges[4].sattyid)
        create(:travel_board_schedule, tbro: "RO13",
                                       tbstdate: Date.parse("2018-04-16"), tbenddate: Date.parse("2018-04-20"),
                                       tbmem1: judges[5].sattyid,
                                       tbmem2: judges[6].sattyid)
      end

      let(:judges) do
        judges = []
        date_count = {}
        80.times do
          judge = create(:user)
          get_unique_dates_between(schedule_period.start_date, schedule_period.end_date,
                                   Random.rand(1..50)).map do |date|
            date_count[date] ||= 0
            next unless date_count[date] < 10

            create(:judge_non_availability, date: date, schedule_period_id: schedule_period.id,
                                            object_identifier: judge.css_id)
            date_count[date] += 1
          end
          judges << create(:staff, :hearing_judge, sdomainid: judge.css_id)
        end
        judges
      end

      subject { assign_judges_to_hearing_days.match_hearing_days_to_judges }

      it "returns all the hearing days allocated to judges",
         skip: "failing on circle CI but not locally" do
        day_count = hearing_days.reduce(0) do |acc, (_id, hearing_day)|
          acc += 1 unless hearing_day.folder_nr.nil? && !hearing_day.hearing_date.to_date.wednesday?
          acc
        end

        expect(subject.count).to eq(day_count)
      end

      it "all hearing days should be assigned to judges", skip: "This test is flaky." do
        judge_count = {}
        subject.each do |hearing_day|
          expected_day = hearing_days[hearing_day[:id]]
          is_co = expected_day.folder_nr.nil?
          judge_count[hearing_day[:judge_id]] ||= 0
          judge_count[hearing_day[:judge_id]] += 1

          type = is_co ? HearingDay::REQUEST_TYPES[:central] : HearingDay::REQUEST_TYPES[:video]
          ro = is_co ? nil : expected_day.folder_nr.split(" ")[1]

          expect(expected_day).to_not be_nil
          expect(hearing_day[:request_type]).to eq(type)
          expect(hearing_day[:hearing_date]).to eq(expected_day.hearing_date.to_date)
          expect(hearing_day[:room]).to eq(expected_day.room)
          expect(hearing_day[:regional_office]).to eq(ro)
          expect(hearing_day[:judge_id]).to_not be_nil
          expect(hearing_day[:judge_name]).to_not be_nil
        end
      end
    end
  end
end
