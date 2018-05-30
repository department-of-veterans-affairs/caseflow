describe HearingSchedule::GenerateHearingDaysSchedule do
  let(:board_non_available_days) do
    [
      Date.parse("2018-04-03"),
      Date.parse("2018-04-09"),
      Date.parse("2018-05-04"),
      Date.parse("2018-06-10"),
      Date.parse("2018-06-19"),
      Date.parse("2018-06-24"),
      Date.parse("2018-06-25"),
      Date.parse("2018-07-11"),
      Date.parse("2018-07-15"),
      Date.parse("2018-07-19"),
      Date.parse("2018-08-27"),
      Date.parse("2018-07-28"),
      Date.parse("2018-10-13"),
      Date.parse("2018-07-17")
    ]
  end

  let(:ro_non_available_days) do
    { 
      "RO01" => [
        Date.parse("2018-04-03"),
        Date.parse("2018-04-06"),
        Date.parse("2018-04-10"),
        Date.parse("2018-04-18"),
        Date.parse("2018-05-30"),
        Date.parse("2018-05-29"),
        Date.parse("2018-06-07"),
        Date.parse("2018-06-14")
      ],
      "RO03" => [
        Date.parse("2018-04-03"),
        Date.parse("2018-04-06"),
        Date.parse("2018-04-10"),
        Date.parse("2018-04-18"),
        Date.parse("2018-05-30"),
        Date.parse("2018-05-29"),
        Date.parse("2018-06-26"),
        Date.parse("2018-06-21"),
        Date.parse("2018-06-15"),
        Date.parse("2018-06-13"),
        Date.parse("2018-07-04") 
      ]
    }
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
      Date.parse("2018-04-01"),
      Date.parse("2018-09-30"),
      board_non_available_days,
    )
  end

  let(:generate_hearing_days_schedule_removed_ro_na) do
    HearingSchedule::GenerateHearingDaysSchedule.new(
      Date.parse("2018-04-01"),
      Date.parse("2018-09-30"),
      board_non_available_days,
      ro_non_available_days
    )
  end

  # generating a schedule for 2025
  let(:generate_hearing_days_schedule2) do
    HearingSchedule::GenerateHearingDaysSchedule.new(
      Date.parse("2025-04-01"),
      Date.parse("2025-09-30"),
      board_non_available_days.map { |day| day + 7.years }
    )
  end

  context "gets all available business days between a date range" do
    subject { generate_hearing_days_schedule.available_days }

    it "has avaiable hearing days" do
      expect(subject.count).to be > 100
    end

    it "removes weekends" do
      expect(subject.find { |day| day.saturday? || day.sunday? }).to eq nil
    end

    it "removes board non-available days" do
      expect(subject.find { |day| board_non_available_days.include?(day) }).to eq nil
    end
  end

  context "change the year" do
    subject { generate_hearing_days_schedule2.available_days }

    it "removes holidays" do
      expect(subject.find { |day| federal_holidays.include?(day) }).to eq nil
    end
  end

  context "RO available days" do
    subject { generate_hearing_days_schedule }

    it "assigns ros to initial available days" do
      subject.ros.map { |key, value| expect(subject.ros[key][:available_days]).to eq subject.available_days }
    end
  end

  context "filters RO non-avaiable days for each RO" do
    subject { generate_hearing_days_schedule_removed_ro_na } 

    it "remove non-available_days" do
      subject.ros.each do |key, value|
        value[:available_days].each { |date| expect((ro_non_available_days[key] || []).include?(date)).not_to eq true }        
      end
    end
  end
end
