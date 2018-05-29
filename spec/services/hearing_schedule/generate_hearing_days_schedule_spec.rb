describe HearingSchedule::GenerateHearingDaysSchedule do
  let(:board_non_available_days) {
    [
      Date.parse("2018-04-2018"),
      Date.parse("2018-04-2018"),
      Date.parse("2018-05-2018"),
      Date.parse("2018-07-2018"),
      Date.parse("2018-07-2018"),
      Date.parse("2018-07-2018"),
      Date.parse("2018-04-2018"),
      Date.parse("2018-04-2018"),
      Date.parse("2018-04-2018"),
      Date.parse("2018-04-2018")
    ]
  }

  let(:generate_hearing_days_schedule) { HearingSchedule::GenerateHearingDaysSchedule.new(
    Date.parse("2019-04-01"),
    Date.parse("2019-09-30")
  )}

  context "gets all available business days between a date range" do
    it "gets available business days " do
      binding.pry
      puts generate_hearing_days_schedule.avaiable_days
    end
  end
end
