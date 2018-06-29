describe HearingSchedule::GenerateHearingDaysSchedule do
  let(:schedule_period) { create(:ro_schedule_period) }

  let(:co_non_available_days) do
    get_unique_dates_between(schedule_period.start_date, schedule_period.end_date, 15).map do |date|
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

  let(:ro_non_available_days) do
    {
      "RO01" => ro_one_non_available_days,
      "RO03" => ro_three_non_available_days
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
      # total 110 weekdays - (15 N/A days + 4 holidays) = 91
      expect(subject.count).to be 91
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

    context "Travelboard hearing days" do
      let(:travel_board_schedules) do
        [
          create(:travel_board_schedule),
          create(:travel_board_schedule, tbstdate: Date.parse("2018-06-18"), tbenddate: Date.parse("2018-06-22")),
          create(:travel_board_schedule, tbro: "RO03",
                                         tbstdate: Date.parse("2018-07-09"), tbenddate: Date.parse("2018-07-13")),
          create(:travel_board_schedule, tbro: "RO17",
                                         tbstdate: Date.parse("2018-07-09"), tbenddate: Date.parse("2018-07-13")),
          create(:travel_board_schedule, tbro: "RO21",
                                         tbstdate: Date.parse("2018-08-13"), tbenddate: Date.parse("2018-08-17"))

        ]
      end

      let(:generate_hearing_days_schedule_removed_tb) do
        HearingSchedule::GenerateHearingDaysSchedule.new(
          schedule_period
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
end
