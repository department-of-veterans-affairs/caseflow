describe HearingSchedule::GenerateHearingDaysSchedule do
  let(:schedule_period) { create(:ro_schedule_period) }

  let(:co_non_available_days) do
    [
      create(:co_non_availability, date: Date.parse("2018-04-03"), schedule_period_id: schedule_period.id),
      create(:co_non_availability, date: Date.parse("2018-04-09"), schedule_period_id: schedule_period.id),
      create(:co_non_availability, date: Date.parse("2018-05-04"), schedule_period_id: schedule_period.id),
      create(:co_non_availability, date: Date.parse("2018-06-10"), schedule_period_id: schedule_period.id),
      create(:co_non_availability, date: Date.parse("2018-06-19"), schedule_period_id: schedule_period.id),
      create(:co_non_availability, date: Date.parse("2018-06-19"), schedule_period_id: schedule_period.id),
      create(:co_non_availability, date: Date.parse("2018-06-24"), schedule_period_id: schedule_period.id),
      create(:co_non_availability, date: Date.parse("2018-06-25"), schedule_period_id: schedule_period.id),
      create(:co_non_availability, date: Date.parse("2018-07-11"), schedule_period_id: schedule_period.id),
      create(:co_non_availability, date: Date.parse("2018-07-15"), schedule_period_id: schedule_period.id),
      create(:co_non_availability, date: Date.parse("2018-07-19"), schedule_period_id: schedule_period.id),
      create(:co_non_availability, date: Date.parse("2018-08-27"), schedule_period_id: schedule_period.id),
      create(:co_non_availability, date: Date.parse("2018-07-28"), schedule_period_id: schedule_period.id),
      create(:co_non_availability, date: Date.parse("2018-10-13"), schedule_period_id: schedule_period.id),
      create(:co_non_availability, date: Date.parse("2018-07-17"), schedule_period_id: schedule_period.id)
    ]
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

  let(:generate_hearing_days_schedule) do
    HearingSchedule::GenerateHearingDaysSchedule.new(
      schedule_period,
      co_non_available_days
    )
  end

  context "gets all available business days between a date range" do
    subject { generate_hearing_days_schedule.available_days }

    it "has available hearing days" do
      expect(subject.count).to be 118
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

    subject { generate_hearing_days_schedule.available_days }

    it "removes holidays" do
      expect(subject.find { |day| federal_holidays.include?(day) }).to eq nil
    end
  end
end
