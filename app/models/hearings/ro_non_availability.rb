class RoNonAvailability < NonAvailability
  class << self
    def import_ro_non_availability(schedule_period)
      dates = HearingSchedule::GetSpreadsheetData.new(schedule_period.spreadsheet).ro_non_availability_data
      ro_non_availability = []
      dates.each do |date|
        ro_non_availability << RoNonAvailability.create!(schedule_period: schedule_period,
                                                         date: date["date"],
                                                         object_identifier: date["ro_code"])
      end
      ro_non_availability
    end
  end
end
