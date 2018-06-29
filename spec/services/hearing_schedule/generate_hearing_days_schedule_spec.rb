describe HearingSchedule::GenerateHearingDaysSchedule do
  let(:schedule_period) { create(:ro_schedule_period) }

  let(:co_non_available_days) do
    get_unique_dates_between(schedule_period.start_date, schedule_period.end_date,
}    ).map do |date|
      create(:co_non_availability, date: date, schedule_period_id: schedule_period.id)
    end
  end
  let(:ro_one_non_available_days) do
    get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 8).map do |date|
      create(:ro_non_availability, date: date, schedule_period_id: schedule_period.id, object_identifier: "RO01")
    end
  end

  let(:ro_three_non_available_days) do
    get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 11).map do |date|
      create(:ro_non_availability, date: date, schedule_period_id: schedule_period.id, object_identifier: "RO03")
    end
  end

  let(:ro_allocations) do
    [
      create(:allocation, regional_office: "RO17", allocated_days: 118, schedule_period: schedule_period),
      create(:allocation, regional_office: "RO61", allocated_days: 66, schedule_period: schedule_period),
      create(:allocation, regional_office: "RO18", allocated_days: 61, schedule_period: schedule_period),
      create(:allocation, regional_office: "RO22", allocated_days: 55, schedule_period: schedule_period),
      create(:allocation, regional_office: "RO01", allocated_days: 24, schedule_period: schedule_period),
      create(:allocation, regional_office: "RO55", allocated_days: 6, schedule_period: schedule_period),
      create(:allocation, regional_office: "RO02", allocated_days: 3, schedule_period: schedule_period)
    ]
  end

  let(:ro_non_available_days) do
    {
      "RO17" => get_unique_dates_for_ro_between("RO17", schedule_period, 25),
      "RO61" => get_unique_dates_for_ro_between("RO61", schedule_period, 15),
      "RO18" => get_unique_dates_for_ro_between("RO18", schedule_period, 10),
      "RO22" => get_unique_dates_for_ro_between("RO22", schedule_period, 18),
      "RO01" => get_unique_dates_for_ro_between("RO01", schedule_period, 20),
      "RO55" => get_unique_dates_for_ro_between("RO55", schedule_period, 25),
      "RO02" => get_unique_dates_for_ro_between("RO02", schedule_period, 20)
    }
  end

  let(:no_ro_non_available_days) do
    {
      "RO17" => get_unique_dates_for_ro_between("RO17", schedule_period, 0),
      "RO61" => get_unique_dates_for_ro_between("RO61", schedule_period, 0),
      "RO18" => get_unique_dates_for_ro_between("RO18", schedule_period, 0),
      "RO22" => get_unique_dates_for_ro_between("RO22", schedule_period, 0),
      "RO01" => get_unique_dates_for_ro_between("RO01", schedule_period, 0),
      "RO55" => get_unique_dates_for_ro_between("RO55", schedule_period, 0),
      "RO02" => get_unique_dates_for_ro_between("RO02", schedule_period, 0)
    }
  end

  let(:generate_hearing_days_schedule) do
    HearingSchedule::GenerateHearingDaysSchedule.new(
      schedule_period,
      co_non_available_days
    )
  end

  context "gets all available business days between a date range" do
    subject { generate_hearing_days_schedule.available_days }

    it "has available hearing days" do
      # total 130 weekdays - (15 N/A days + 3 holidays) = 112
      expect(subject.count).to be 112
    end

    it "removes weekends" do
      expect(subject.find { |day| day.saturday? || day.sunday? }).to eq nil
    end

    it "removes board non-available days" do
      expect(subject.find { |day| co_non_available_days.include?(day) }).to eq nil
    end
  end

  context "change the year" do
    # generating a schedule for 2025
    let(:generate_hearing_days_schedule) do
      HearingSchedule::GenerateHearingDaysSchedule.new(
        schedule_period,
        co_non_available_days.map do |day|
          day.date += 7.years
          day
        end
      )
    end

    let(:federal_holidays) do
      [
        Date.parse("2025-01-01"),
        Date.parse("2025-01-20"),
        Date.parse("2025-02-17"),
        Date.parse("2025-05-26"),
        Date.parse("2025-07-04"),
        Date.parse("2025-09-01"),
        Date.parse("2025-10-13"),
        Date.parse("2025-11-11"),
        Date.parse("2025-11-27"),
        Date.parse("2025-12-25")
      ]
    end

    subject { generate_hearing_days_schedule.available_days }

    it "removes holidays" do
      expect(subject.find { |day| federal_holidays.include?(day) }).to eq nil
    end
  end

  context "verify ro available days" do
    let(:generate_hearing_days_schedule_removed_ro_na) do
      HearingSchedule::GenerateHearingDaysSchedule.new(
        schedule_period,
        co_non_available_days,
        no_ro_non_available_days
      )
    end

    context "RO available days" do
      subject { generate_hearing_days_schedule_removed_ro_na }

      it "assigns ros to initial available days" do
        subject.ros.map { |key, _value| expect(subject.ros[key][:available_days]).to eq subject.available_days }
      end
    end
  end

  context "filter available days" do
    let(:generate_hearing_days_schedule_removed_ro_na) do
      HearingSchedule::GenerateHearingDaysSchedule.new(
        schedule_period,
        co_non_available_days,
        ro_non_available_days
      )
    end

    context "RO available days" do
      subject { generate_hearing_days_schedule_removed_ro_na }

      it "assigns ros to initial available days" do
        subject.ros.map { |key, _value| expect(subject.ros[key][:available_days]).to eq subject.available_days }
      end

      it "remove non-available_days" do
        subject.ros.each do |key, value|
          includes_ro_days = value[:available_days].map do |date|
            (ro_non_available_days[key] || []).include?(date)
          end

          expect(includes_ro_days.any?).to eq false
        end
      end
    end

    context "RO-non avaiable days not provided" do
      before do
        ro_allocations
      end

      subject { generate_hearing_days_schedule_removed_ro_na }
      let(:ro_non_available_days) do
        {
          "RO17" => get_unique_dates_for_ro_between("RO17", schedule_period, 25)
        }
      end

      it "throws an ro non-avaiable days not provided" do
        expect { subject }.to raise_error(HearingSchedule::GenerateHearingDaysSchedule::RoNonAvailableDaysNotProvided)
      end
    end

    context "Travelboard hearing days" do
      before do
        ro_allocations
      end

      let(:travel_board_schedules) do
        [
          create(:travel_board_schedule),
          create(:travel_board_schedule, tbro: "RO17",
                                         tbstdate: Date.parse("2018-06-04"), tbenddate: Date.parse("2018-06-08")),
          create(:travel_board_schedule, tbro: "RO17",
                                         tbstdate: Date.parse("2018-07-09"), tbenddate: Date.parse("2018-07-13")),
          create(:travel_board_schedule, tbro: "RO18",
                                         tbstdate: Date.parse("2018-08-27"), tbenddate: Date.parse("2018-08-31")),
          create(:travel_board_schedule, tbro: "RO01",
                                         tbstdate: Date.parse("2018-04-23"), tbenddate: Date.parse("2018-04-27")),
          create(:travel_board_schedule, tbro: "RO55",
                                         tbstdate: Date.parse("2018-04-09"), tbenddate: Date.parse("2018-04-13")),
          create(:travel_board_schedule, tbro: "RO22",
                                         tbstdate: Date.parse("2018-05-14"), tbenddate: Date.parse("2018-05-18")),
          create(:travel_board_schedule, tbro: "RO02",
                                         tbstdate: Date.parse("2018-05-14"), tbenddate: Date.parse("2018-05-18")),
          create(:travel_board_schedule, tbro: "RO02",
                                         tbstdate: Date.parse("2018-05-21"), tbenddate: Date.parse("2018-05-25"))

        ]
      end

      let(:generate_hearing_days_schedule_removed_tb) do
        HearingSchedule::GenerateHearingDaysSchedule.new(
          schedule_period,
          {},
          no_ro_non_available_days
        )
      end

      subject { generate_hearing_days_schedule_removed_tb }

      it "travel board hearing days removed" do

        travel_board_schedules.each do |tb_schedule|
          dates = (tb_schedule[:tbstdate]..tb_schedule[:tbenddate]).to_a
          expect(dates.map { |date| subject.ros[tb_schedule[:tbro]][:available_days].include?(date) }.any?).to eq false
        end
      end
    end
  end

  context ".monthly_distributed_weights" do
    let(:monthly_weights) do 
      { [4, 2018] => 0.16666666666666666, [5, 2018] => 0.16666666666666666,
                             [6, 2018] => 0.16666666666666666, [7, 2018] => 0.16666666666666666, [8, 2018] => 0.16666666666666666,
                             [9, 2018] => 0.16666666666666666 } end
    let(:allocated_days) { 118.0 }
    subject { generate_hearing_days_schedule.monthly_distributed_weights(monthly_weights, allocated_days) }

    it { expect(subject).to eq({ [4, 2018] => 20, [5, 2018] => 19, [6, 2018] => 20, [7, 2018] => 20, [8, 2018] => 19, [9, 2018] => 20 }) }
    it { expect(subject.values.inject(:+).to_f).to eq(allocated_days) }

    context "for a few months" do
      let(:monthly_weights) { { [8, 2018] => 0.5, [9, 2018] => 0.5 } }
      let(:allocated_days) { 3.0 }

      it { expect(subject).to eq({ [8, 2018] => 2, [9, 2018] => 1 }) }
      it { expect(subject.values.inject(:+).to_f).to eq(allocated_days) }
    end
  end

  context "RO hearing days allocation" do
    let(:generate_hearing_days_schedule) do
      HearingSchedule::GenerateHearingDaysSchedule.new(
        schedule_period,
        co_non_available_days,
        ro_non_available_days
      )
    end

    subject { generate_hearing_days_schedule.allocate_hearing_days_to_ros }

    context "allocated days to ros" do
      it "assigned as rooms" do
        allocations = ro_allocations.reduce({}) { |acc, ro| acc[ro.regional_office] = ro.allocated_days; acc }

        expect(subject.keys).to eq(allocations.keys)

        subject.each_key do |ro_key|
          rooms = subject[ro_key][:allocated_dates].reduce({}) do |acc, (k, v)|
            acc[k] = acc[k] || 0
            acc[k] += v.values.map { |a| a.size }.inject(:+)
            acc
          end

          # making sure rooms are filled
          if subject[ro_key][:allocated_days] % subject[ro_key][:num_of_rooms] == 0
            expect(rooms.map { |_key, num| num % subject[ro_key][:num_of_rooms] == 0 }.all?).to eq(true)
          else
            expect(rooms.map { |_key, num| num % subject[ro_key][:num_of_rooms] == 0 }.count(false)).to eq(1)
          end

          expect(rooms.values.inject(:+)).to eq(allocations[ro_key])
        end
      end
    end
  end

end
