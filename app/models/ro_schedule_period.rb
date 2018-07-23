class RoSchedulePeriod < SchedulePeriod
  before_create :validate_spreadsheet
  after_create :import_spreadsheet

  def validate_spreadsheet
    HearingSchedule::ValidateRoSpreadsheet.new(spreadsheet, start_date, end_date).validate
  end

  def import_spreadsheet
    RoNonAvailability.import_ro_non_availability(self)
    CoNonAvailability.import_co_non_availability(self)
    Allocation.import_allocation(self)
  end
end
