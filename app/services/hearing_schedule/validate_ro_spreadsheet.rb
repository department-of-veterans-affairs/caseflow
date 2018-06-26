class HearingSchedule::ValidateRoSpreadsheet
  RO_NON_AVAILABILITY_TITLE = "Regional Office Non-Availability Dates in Date Range".freeze
  RO_NON_AVAILABILITY_EXAMPLE_ROW = ["Example", "RO00", "Ithaca, NY", Date.parse("2019/01/01"),
                                     Date.parse("2019/02/01"), Date.parse("2019/03/16"), Date.parse("2019/04/21"),
                                     Date.parse("2019/05/19"), nil].freeze
  RO_NON_AVAILABILITY_EMPTY_COLUMN = [nil].freeze

  CO_SPREADSHEET_TITLE = "Board Non-Availability Dates and Holidays in Date Range".freeze
  CO_SPREADSHEET_EXAMPLE_ROW = ["Example", Date.parse("2018/10/31")].freeze
  CO_SPREADSHEET_EMPTY_COLUMN = [nil].freeze

  HEARING_ALLOCATION_SHEET_TITLE = "Allocation of Regional Office Video Hearings and Central Office Hearings".freeze
  HEARING_ALLOCATION_SHEET_EXAMPLE_ROW = ["Example", "Ithaca, NY", "RO00", 10].freeze
  HEARING_ALLOCATION_SHEET_EMPTY_COLUMN = [nil].freeze

  class RoDatesNotUnique < StandardError; end
  class RoDatesNotInRange < StandardError; end
  class RoDatesNotCorrectFormat < StandardError; end
  class RoTemplateNotFollowed < StandardError; end
  class RoListedIncorrectly < StandardError; end
  class CoDatesNotUnique < StandardError; end
  class CoDatesNotInRange < StandardError; end
  class CoDatesNotCorrectFormat < StandardError; end
  class CoTemplateNotFollowed < StandardError; end
  class AllocationNotCorrectFormat < StandardError; end
  class AllocationRoListedIncorrectly < StandardError; end
  class AllocationDuplicateRo < StandardError; end
  class AllocationCoLocationIncorrect < StandardError; end
  class AllocationTemplateNotFollowed < StandardError; end

  def initialize(spreadsheet, start_date, end_date)
    get_spreadsheet_data = HearingSchedule::GetSpreadsheetData.new(spreadsheet)
    @ro_spreadsheet_template = get_spreadsheet_data.ro_non_availability_template
    @ro_spreadsheet_data = get_spreadsheet_data.ro_non_availability_data
    @co_spreadsheet_template = get_spreadsheet_data.co_non_availability_template
    @co_spreadsheet_data = get_spreadsheet_data.co_non_availability_data
    @allocation_spreadsheet_template = get_spreadsheet_data.allocation_template
    @allocation_spreadsheet_ro_data = get_spreadsheet_data.allocation_ro_data
    @allocation_spreadsheet_co_data = get_spreadsheet_data.allocation_co_data
    @start_date = start_date
    @end_date = end_date
  end

  def validate_ros_with_hearings(spreadsheet_data)
    unless spreadsheet_data.all? do |row|
             RegionalOffice::CITIES[row["ro_code"]][:state] == row["ro_state"].rstrip &&
             RegionalOffice::CITIES[row["ro_code"]][:city] == row["ro_city"].rstrip
           end
      return false
    end
    unless RegionalOffice.ros_with_hearings.keys.sort == spreadsheet_data.collect do |ro|
                                                           ro["ro_code"]
                                                         end.uniq.sort
      return false
    end
    true
  end

  def validate_ro_non_availability_template
    unless @ro_spreadsheet_template[:title] == RO_NON_AVAILABILITY_TITLE &&
           # @ro_spreadsheet_template.row(5)[1] == Date.parse("01/02/2019")  &&
           @ro_spreadsheet_template[:empty_column] == RO_NON_AVAILABILITY_EMPTY_COLUMN
      fail RoTemplateNotFollowed
    end
  end

  def validate_ro_non_availability_dates
    unless @ro_spreadsheet_data.all? { |row| row["date"].instance_of?(Date) }
      fail RoDatesNotCorrectFormat
    end
    unless @ro_spreadsheet_data.uniq == @ro_spreadsheet_data
      fail RoDatesNotUnique
    end
    unless @ro_spreadsheet_data.all? { |row| row["date"] >= @start_date && row["date"] <= @end_date }
      fail RoDatesNotInRange
    end
    unless validate_ros_with_hearings(@ro_spreadsheet_data)
      fail RoListedIncorrectly
    end
    true
  end

  def validate_co_non_availability_template
    unless @co_spreadsheet_template[:title] == CO_SPREADSHEET_TITLE &&
           @co_spreadsheet_template[:example_row] == CO_SPREADSHEET_EXAMPLE_ROW &&
           @co_spreadsheet_template[:empty_column] == CO_SPREADSHEET_EMPTY_COLUMN
      fail CoTemplateNotFollowed
    end
  end

  def validate_co_non_availability_dates
    unless @co_spreadsheet_data.all? { |date| date.instance_of?(Date) }
      fail CoDatesNotCorrectFormat
    end
    unless @co_spreadsheet_data.uniq == @co_spreadsheet_data
      fail CoDatesNotUnique
    end
    unless @co_spreadsheet_data.all? { |date| date >= @start_date && date <= @end_date }
      fail CoDatesNotInRange
    end
    true
  end

  def hearing_ro_allocation_days
    hearing_allocation_days = []
    ro_names = hearing_allocation_template.column(2).drop(4)
    ro_codes = hearing_allocation_template.column(3).drop(4)
    allocated_days = hearing_allocation_template.column(4).drop(4)
    ro_names.zip(ro_codes, allocated_days).each do |row|
      hearing_allocation_days.push("ro_code" => row[1],
                                   "ro_city" => row[0].split(", ")[0],
                                   "ro_state" => row[0].split(", ")[1],
                                   "allocated_days" => row[2])
    end
    hearing_allocation_days
  end

  def hearing_co_allocation_days
    {
      location: hearing_allocation_template.row(4)[1],
      allocated_days: hearing_allocation_template.row(4)[3]
    }
  end

  def validate_hearing_allocation_template
    unless @allocation_spreadsheet_template[:title] == HEARING_ALLOCATION_SHEET_TITLE &&
           @allocation_spreadsheet_template[:example_row] == HEARING_ALLOCATION_SHEET_EXAMPLE_ROW &&
           @allocation_spreadsheet_template[:empty_column] == HEARING_ALLOCATION_SHEET_EMPTY_COLUMN
      fail AllocationTemplateNotFollowed
    end
  end

  def validate_hearing_ro_allocation_days
    unless @allocation_spreadsheet_ro_data.all? { |row| row["allocated_days"].is_a?(Numeric) }
      fail AllocationNotCorrectFormat
    end
    unless validate_ros_with_hearings(@allocation_spreadsheet_ro_data)
      fail AllocationRoListedIncorrectly
    end
    ro_codes = @allocation_spreadsheet_ro_data.collect { |ro| ro["ro_code"] }
    unless ro_codes.uniq == ro_codes
      fail AllocationDuplicateRo
    end
    true
  end

  def validate_hearing_co_allocation_days
    unless @allocation_spreadsheet_co_data["ro_code"] == "Central Office"
      fail AllocationCoLocationIncorrect
    end
    unless @allocation_spreadsheet_co_data["allocated_days"].is_a?(Numeric)
      fail AllocationNotCorrectFormat
    end
  end

  def validate
    validate_ro_non_availability_template
    validate_ro_non_availability_dates
    validate_co_non_availability_template
    validate_co_non_availability_dates
    validate_hearing_allocation_template
    validate_hearing_co_allocation_days
    validate_hearing_ro_allocation_days
  end
end
