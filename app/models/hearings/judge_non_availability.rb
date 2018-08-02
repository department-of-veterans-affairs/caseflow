class JudgeNonAvailability < NonAvailability
  class << self
    def import_judge_non_availability(schedule_period)
      dates = HearingSchedule::GetSpreadsheetData.new(schedule_period.spreadsheet).judge_non_availability_data
      judge_non_availability = []
      judges = User.css_ids_by_vlj_ids(dates.pluck("vlj_id"))
      transaction do
        dates.each do |date|
          css_id = judges[date["vlj_id"]][:css_id]
          judge_non_availability << JudgeNonAvailability.create!(schedule_period: schedule_period,
                                                                 date: date["date"],
                                                                 object_identifier: css_id)
        end
      end
      judge_non_availability
    end
  end
end
