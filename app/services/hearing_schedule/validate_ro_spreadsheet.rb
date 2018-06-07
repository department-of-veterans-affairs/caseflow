class HearingSchedule::ValidateRoSpreadsheet

  RO_NON_AVAILABILITY_SHEET = 0
  CO_NON_AVAILABILITY_SHEET = 1
  HEARING_ALLOCATION_SHEET = 2

  def initialize(spreadsheet)
    @spreadsheet = spreadsheet
  end

  def co_non_availability_dates
    @spreadsheet.sheet(CO_NON_AVAILABILITY_SHEET).column(2).drop(2)
  end

  def validate_co_non_availability
    co_non_availability_dates.uniq == co_non_availability_dates
  end

  def validate
    validate_co_non_availability
  end
end
