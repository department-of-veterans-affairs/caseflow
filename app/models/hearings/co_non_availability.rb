class CoNonAvailability < NonAvailability
  class << self
    def import_co_non_availability(schedule_period)
      dates = HearingSchedule::GetSpreadsheetData.new(schedule_period.spreadsheet).co_non_availability_data
      co_non_availability = []
      dates.each do |date|
        co_non_availability << CoNonAvailability.create!(schedule_period: schedule_period,
                                                         date: date,
                                                         object_identifier: "CO")
      end
      co_non_availability
    end
  end
end
