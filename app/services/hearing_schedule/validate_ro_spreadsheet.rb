class HearingSchedule::ValidateRoSpreadsheet
  RO_NON_AVAILABILITY_SHEET = 0
  CO_NON_AVAILABILITY_SHEET = 1
  HEARING_ALLOCATION_SHEET = 2

  class CoDatesNotUnique < StandardError; end
  class CoDatesNotInRange < StandardError; end
  class CoDatesNotCorrectFormat < StandardError; end
  class CoTemplateNotFollowed < StandardError; end

  def initialize(spreadsheet, start_date, end_date)
    @spreadsheet = spreadsheet
    @start_date = start_date
    @end_date = end_date
  end

  def co_non_availability_template
    @spreadsheet.sheet(CO_NON_AVAILABILITY_SHEET)
  end

  def co_non_availability_dates
    co_non_availability_template.column(2).drop(2)
  end

  def validate_co_non_availability_template
    unless co_non_availability_template.column(2)[0] == "Board Non-Availability Dates and Holidays in Time Range" &&
           co_non_availability_template.column(2)[1] == Date.parse("31/10/2018") &&
           co_non_availability_template.column(1).uniq == [nil, "Example"] &&
           co_non_availability_template.column(3).uniq == [nil] &&
           co_non_availability_template.row(1).count == 2
      fail CoTemplateNotFollowed
    end
  end

  def validate_co_non_availability_dates
    unless co_non_availability_dates.all? { |date| date.instance_of?(Date) }
      fail CoDatesNotCorrectFormat
    end
    unless co_non_availability_dates.uniq == co_non_availability_dates
      fail CoDatesNotUnique
    end
    unless co_non_availability_dates.all? { |date| date > @start_date && date < @end_date }
      fail CoDatesNotInRange
    end
    true
  end

  def validate
    validate_co_non_availability_template
    validate_co_non_availability_dates
  end
end
