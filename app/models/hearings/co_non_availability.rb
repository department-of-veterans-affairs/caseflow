# frozen_string_literal: true

class CoNonAvailability < NonAvailability
  class << self
    def import_co_non_availability(schedule_period)
      dates = HearingSchedule::GetSpreadsheetData.new(schedule_period.spreadsheet).co_non_availability_data
      co_non_availability = []
      transaction do
        dates.each do |date|
          next if date == "N/A"

          co_non_availability << CoNonAvailability.create!(schedule_period: schedule_period,
                                                           date: date,
                                                           object_identifier: "CO")
        end
      end
      co_non_availability
    end
  end
end
