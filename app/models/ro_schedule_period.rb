class RoSchedulePeriod < SchedulePeriod
  validate :validate_spreadsheet, on: :create
  after_create :import_spreadsheet

  def validate_spreadsheet
    validate_spreadsheet = HearingSchedule::ValidateRoSpreadsheet.new(spreadsheet, start_date, end_date)
    errors[:base] << validate_spreadsheet.validate
  end

  def import_spreadsheet
    RoNonAvailability.import_ro_non_availability(self)
    CoNonAvailability.import_co_non_availability(self)
    Allocation.import_allocation(self)
  end

  def schedule_confirmed(hearing_schedule)
    HearingDay.create_schedule(hearing_schedule)
    super
  end
end
