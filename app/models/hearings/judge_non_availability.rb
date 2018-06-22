class JudgeNonAvailability < NonAvailability
  class << self
    def import_judge_non_availability(schedule_period)
      dates = HearingSchedule::GetSpreadsheetData.new(schedule_period.spreadsheet).judge_non_availability_data
      judge_non_availability = []
      dates.each do |date|
        judge_non_availability << JudgeNonAvailability.create!(schedule_period: schedule_period,
                                                               date: date["date"],
                                                               object_identifier: date["css_id"])
      end
      judge_non_availability
    end
  end
end
