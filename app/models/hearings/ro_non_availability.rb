# frozen_string_literal: true

##
# RoNonAvailability records represents Non-Available days for ROs for a SchedulePeriod. These records are created when
# user uploads RoAssignment spreadsheet after it passes all validations.
##
class RoNonAvailability < NonAvailability
  class << self
    def import_ro_non_availability(schedule_period)
      dates = HearingSchedule::GetSpreadsheetData.new(schedule_period.spreadsheet).ro_non_availability_data
      ro_non_availability = []
      transaction do
        dates.each do |date|
          next if date["date"] == "N/A"

          ro_non_availability << RoNonAvailability.create!(schedule_period: schedule_period,
                                                           date: date["date"],
                                                           object_identifier: date["ro_code"])
        end
      end
      ro_non_availability
    end
  end
end
