# frozen_string_literal: true

class Allocation < CaseflowRecord
  belongs_to :schedule_period

  class << self
    def import_allocation(schedule_period)
      spreadsheet = HearingSchedule::GetSpreadsheetData.new(schedule_period.spreadsheet)
      allocation_data = spreadsheet.allocation_data
      allocation = []
      transaction do
        allocation_data.each do |row|
          allocation << Allocation.create!(schedule_period: schedule_period,
                                           allocated_days: row["allocated_days"],
                                           regional_office: row["ro_code"])
        end
      end
      allocation
    end
  end
end
