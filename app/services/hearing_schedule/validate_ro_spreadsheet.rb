# frozen_string_literal: true

class HearingSchedule::ValidateRoSpreadsheet
  RO_NON_AVAILABILITY_TITLE = "Regional Office Non-Availability Dates in Date Range"
  RO_NON_AVAILABILITY_EXAMPLE_ROW = ["Example", "RO00", "Ithaca, NY", Date.parse("2019/01/01"),
                                     Date.parse("2019/02/01"), Date.parse("2019/03/16"), Date.parse("2019/04/21"),
                                     Date.parse("2019/05/19")].freeze
  RO_NON_AVAILABILITY_EMPTY_COLUMN = [nil].freeze

  CO_SPREADSHEET_TITLE = "Board Non-Availability Dates and Holidays in Date Range"
  CO_SPREADSHEET_EXAMPLE_ROW = ["Example", Date.parse("2018/10/31")].freeze
  CO_SPREADSHEET_EMPTY_COLUMN = [nil].freeze

  HEARING_ALLOCATION_SHEET_TITLE = "Allocation of Regional Office Video Hearings"
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
  class AllocationTemplateNotFollowed < StandardError; end

  def initialize(spreadsheet, start_date, end_date)
    get_spreadsheet_data = HearingSchedule::GetSpreadsheetData.new(spreadsheet)
    @errors = []
    @ro_spreadsheet_template = get_spreadsheet_data.ro_non_availability_template
    @ro_spreadsheet_data = get_spreadsheet_data.ro_non_availability_data
    @co_spreadsheet_template = get_spreadsheet_data.co_non_availability_template
    @co_spreadsheet_data = get_spreadsheet_data.co_non_availability_data
    @allocation_spreadsheet_template = get_spreadsheet_data.allocation_template
    @allocation_spreadsheet_data = get_spreadsheet_data.allocation_data
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
           @ro_spreadsheet_template[:example_row].compact == RO_NON_AVAILABILITY_EXAMPLE_ROW &&
           @ro_spreadsheet_template[:empty_column] == RO_NON_AVAILABILITY_EMPTY_COLUMN
      @errors << RoTemplateNotFollowed
    end
  end

  def validate_ro_date_formats
    @ro_spreadsheet_data.all? do |row|
      row["date"].instance_of?(Date) || row["date"] == "N/A"
    end
  end

  def validate_ro_dates_in_range
    @ro_spreadsheet_data.all? do |row|
      !row["date"].instance_of?(Date) || (row["date"] >= @start_date && row["date"] <= @end_date)
    end
  end

  def validate_ro_non_availability_dates
    @errors << RoDatesNotCorrectFormat unless validate_ro_date_formats
    @errors << RoDatesNotUnique unless @ro_spreadsheet_data.uniq == @ro_spreadsheet_data
    @errors << RoDatesNotInRange unless validate_ro_dates_in_range
    @errors << RoListedIncorrectly unless validate_ros_with_hearings(@ro_spreadsheet_data)
  end

  def validate_co_non_availability_template
    unless @co_spreadsheet_template[:title] == CO_SPREADSHEET_TITLE &&
           @co_spreadsheet_template[:example_row].compact == CO_SPREADSHEET_EXAMPLE_ROW &&
           @co_spreadsheet_template[:empty_column] == CO_SPREADSHEET_EMPTY_COLUMN
      @errors << CoTemplateNotFollowed
    end
  end

  def validate_co_non_availability_dates_formats
    @co_spreadsheet_data.all? do |date|
      date.instance_of?(Date) || date == "N/A"
    end
  end

  def validate_co_non_availability_dates_in_range
    @co_spreadsheet_data.all? do |date|
      !date.instance_of?(Date) || date >= @start_date && date <= @end_date
    end
  end

  def validate_co_non_availability_dates
    @errors << CoDatesNotCorrectFormat unless validate_co_non_availability_dates_formats
    @errors << CoDatesNotUnique unless @co_spreadsheet_data.uniq == @co_spreadsheet_data
    @errors << CoDatesNotInRange unless validate_co_non_availability_dates_in_range
  end

  def validate_hearing_allocation_template
    unless @allocation_spreadsheet_template[:title] == HEARING_ALLOCATION_SHEET_TITLE &&
           @allocation_spreadsheet_template[:example_row].compact == HEARING_ALLOCATION_SHEET_EXAMPLE_ROW &&
           @allocation_spreadsheet_template[:empty_column] == HEARING_ALLOCATION_SHEET_EMPTY_COLUMN
      @errors << AllocationTemplateNotFollowed
    end
  end

  def validate_hearing_allocation_days
    unless @allocation_spreadsheet_data.all? { |row| row["allocated_days"].is_a?(Numeric) }
      @errors << AllocationNotCorrectFormat
    end
    unless validate_ros_with_hearings(@allocation_spreadsheet_data)
      @errors << AllocationRoListedIncorrectly
    end
    ro_codes = @allocation_spreadsheet_data.collect { |ro| ro["ro_code"] }
    unless ro_codes.uniq == ro_codes
      @errors << AllocationDuplicateRo
    end
  end

  def validate
    validate_ro_non_availability_template
    validate_ro_non_availability_dates
    validate_co_non_availability_template
    validate_co_non_availability_dates
    validate_hearing_allocation_template
    validate_hearing_allocation_days
    @errors
  end
end
