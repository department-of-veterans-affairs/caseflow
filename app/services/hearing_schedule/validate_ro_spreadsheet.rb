class HearingSchedule::ValidateRoSpreadsheet
  RO_NON_AVAILABILITY_SHEET = 0
  HEARING_ALLOCATION_SHEET = 2
  HEARING_ALLOCATION_SHEET_TITLE = "Allocation of Regional Office Video Hearings and Central Office Hearings".freeze
  HEARING_ALLOCATION_SHEET_FIRST_SECOND_HEADER_ROW = [nil, "RO City, State", "BFREGOFF",
                                                      "Number of Hearing Days Allocated in Date Range"].freeze

  CO_SPREADSHEET_TITLE = "Board Non-Availability Dates and Holidays in Date Range".freeze
  CO_SPREADSHEET_EXAMPLE_ROW = ["Example", Date.parse("2018/10/31")].freeze
  CO_SPREADSHEET_EMPTY_COLUMN = [nil].freeze

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
  class AllocationNotFollowed < StandardError; end

  def initialize(spreadsheet, start_date, end_date)
    get_spreadsheet_data = HearingSchedule::GetSpreadsheetData.new(spreadsheet)
    @co_spreadsheet_template = get_spreadsheet_data.co_non_availability_template
    @co_spreadsheet_data = get_spreadsheet_data.co_non_availability_data
    @spreadsheet = spreadsheet
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

  def ro_non_availability_template
    @spreadsheet.sheet(RO_NON_AVAILABILITY_SHEET)
  end

  def ro_non_availability_dates
    non_availability_dates = []
    ro_codes = ro_non_availability_template.row(2).drop(2)
    ro_names = ro_non_availability_template.row(3).drop(2)
    ro_codes.zip(ro_names).each_with_index do |row, index|
      dates = ro_non_availability_template.column(index + 3).drop(3).compact
      dates.each do |date|
        non_availability_dates.push("ro_code" => row[0],
                                    "ro_city" => row[1].split(", ")[0],
                                    "ro_state" => row[1].split(", ")[1],
                                    "date" => date)
      end
    end
    non_availability_dates
  end

  def validate_ro_non_availability_template; end

  def validate_ro_non_availability_dates
    unless ro_non_availability_dates.all? { |row| row["date"].instance_of?(Date) }
      fail RoDatesNotCorrectFormat
    end
    unless ro_non_availability_dates.uniq == ro_non_availability_dates
      fail RoDatesNotUnique
    end
    unless ro_non_availability_dates.all? { |row| row["date"] >= @start_date && row["date"] <= @end_date }
      fail RoDatesNotInRange
    end
    unless validate_ros_with_hearings(ro_non_availability_dates)
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

  def hearing_allocation_template
    @spreadsheet.sheet(HEARING_ALLOCATION_SHEET)
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
    unless hearing_allocation_template.row(1)[0] == HEARING_ALLOCATION_SHEET_TITLE &&
           hearing_allocation_template.column(1)[3].nil? &&
           hearing_allocation_template.column(5).uniq == [nil] &&
           hearing_allocation_template.row(2).uniq == HEARING_ALLOCATION_SHEET_FIRST_SECOND_HEADER_ROW
      fail AllocationNotFollowed
    end
  end

  def validate_hearing_ro_allocation_days
    unless hearing_ro_allocation_days.all? { |row| row["allocated_days"].is_a?(Numeric) }
      fail AllocationNotCorrectFormat
    end
    unless validate_ros_with_hearings(hearing_ro_allocation_days)
      fail AllocationRosListedIncorrectly
    end
    ro_codes = hearing_ro_allocation_days.collect { |ro| ro["ro_code"] }
    unless ro_codes.uniq == ro_codes
      fail AllocationDuplicateRo
    end
    true
  end

  def validate_hearing_co_allocation_days
    unless hearing_co_allocation_days[:location] == "Central Office"
      fail AllocationCoLocationIncorrect
    end
    unless hearing_co_allocation_days[:allocated_days].is_a?(Numeric)
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
