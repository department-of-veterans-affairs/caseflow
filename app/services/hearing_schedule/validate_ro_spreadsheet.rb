class HearingSchedule::ValidateRoSpreadsheet
  RO_NON_AVAILABILITY_SHEET = 0
  CO_NON_AVAILABILITY_SHEET = 1
  HEARING_ALLOCATION_SHEET = 2
  RO_NON_AVAILABILITY_TITLE = "Regional Office Non-Availability Dates in Date Range".freeze
  RO_NON_AVAILABILITY_FIRST_HEADER_COLUMN = ["BFREGOFF", "RO City,State", "Dates"].freeze
  FIFTH_EXAMPLE_ROW = [nil, Date.parse("01/02/2019")].freeze

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

  def initialize(spreadsheet, start_date, end_date)
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

  def validate_ro_non_availability_template
    unless ro_non_availability_template.column(1)[0] == RO_NON_AVAILABILITY_TITLE &&
           ro_non_availability_template.row(5).uniq == FIFTH_EXAMPLE_ROW &&
           ro_non_availability_template.column(60).uniq == [nil] &&
           ro_non_availability_template.column(1).uniq == RO_NON_AVAILABILITY_FIRST_HEADER_COLUMN
      fail RoTemplateNotFollowed
    end
  end

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

  def co_non_availability_template
    @spreadsheet.sheet(CO_NON_AVAILABILITY_SHEET)
  end

  def co_non_availability_dates
    co_non_availability_template.column(2).drop(3)
  end

  def validate_co_non_availability_template
    unless co_non_availability_template.row(1)[0] == "Board Non-Availability Dates and Holidays in Date Range" &&
           co_non_availability_template.column(2)[2] == Date.parse("31/10/2018") &&
           co_non_availability_template.column(1).uniq == ["Board Non-Availability Dates and Holidays in Date Range",
                                                           nil, "Example"] &&
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
    unless co_non_availability_dates.all? { |date| date >= @start_date && date <= @end_date }
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

  def validate_hearing_allocation_template; end

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
