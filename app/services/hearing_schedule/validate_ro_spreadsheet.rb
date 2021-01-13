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
  HEARING_ALLOCATION_SHEET_EXAMPLE_ROW = ["Example", "Ithaca, NY", "RO00", 10, 50].freeze
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

  RO_TEMPLATE_ERROR = "The RO non-availability template was not followed. Redownload the template and try again."
  CO_TEMPLATE_ERROR = "The CO non-availability template was not followed. Redownload the template and try again."
  ALLOCATION_TEMPLATE_ERROR = "The allocation template was not followed. Redownload the template and try again."
  RO_DATES_NOT_CORRECT_FORMAT = "The following dates are incorrectly formatted in the RO spreadsheet: "
  RO_DATES_NOT_IN_RANGE = "The following dates in the RO spreadsheet are out of range: "
  RO_LISTED_INCORRECTLY = "The ROs are listed incorrectly in the RO spreadsheet. Redownload the template and try again."
  CO_DATES_NOT_CORRECT_FORMAT = "The following dates are incorrectly formatted in the CO spreadsheet: "
  CO_DATES_NOT_UNIQUE = "The following dates in the CO spreadsheet are listed more than once: "
  CO_DATES_NOT_IN_RANGE = "The following dates in the CO spreadsheet are out of range: "
  ALLOCATION_NOT_CORRECT_FORMAT = "The following allocations are incorrectly formatted: "
  ALLOCATION_LISTED_INCORRECTLY = "The ROs are listed incorrectly in the allocation spreadsheet. " \
                                  "Redownload the template and try again."
  ALLOCATION_DUPLICATE_RO = "The following ROs are listed more than once in the allocation spreadsheet: "

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

  # Verifies that the spreadsheet city and state data all match for the respective ROs,
  # and that every RO key appears in the spreadsheet data.
  def validate_ros_with_hearings(spreadsheet_data)
    city_state_match = spreadsheet_data.all? do |row|
      ro = RegionalOffice.find!(row["ro_code"])
      ro.state == row["ro_state"].rstrip && ro.city == row["ro_city"].rstrip
    end

    # Right now, exclude virtual regional offices since they can't be added to the RO spreadsheet.
    all_ro_keys = RegionalOffice
      .ros_with_hearings
      .keys
      .reject { |ro_key| ro_key == HearingDay::REQUEST_TYPES[:virtual] } # Remove for CASEFLOW-408
      .sort
    spreadsheet_ro_keys = spreadsheet_data.collect { |ro| ro["ro_code"] }.uniq.sort
    all_ro_keys_appear = all_ro_keys == spreadsheet_ro_keys

    city_state_match && all_ro_keys_appear
  end

  def validate_ro_non_availability_template
    unless @ro_spreadsheet_template[:title] == RO_NON_AVAILABILITY_TITLE &&
           @ro_spreadsheet_template[:example_row].compact == RO_NON_AVAILABILITY_EXAMPLE_ROW &&
           @ro_spreadsheet_template[:empty_column] == RO_NON_AVAILABILITY_EMPTY_COLUMN
      @errors << RoTemplateNotFollowed.new(RO_TEMPLATE_ERROR)
    end
  end

  def filter_incorrectly_formatted_ro_dates
    @ro_spreadsheet_data.reject do |row|
      HearingSchedule::DateValidators.new(row["date"]).date_correctly_formatted?
    end.pluck("date")
  end

  def filter_nonunique_ro_dates
    HearingSchedule::UniquenessValidators.new(@ro_spreadsheet_data).duplicate_rows.pluck("ro_code").uniq
  end

  def filter_out_of_range_ro_dates
    out_of_range_dates = @ro_spreadsheet_data.reject do |row|
      HearingSchedule::DateValidators.new(row["date"], @start_date, @end_date).date_in_range?
    end.pluck("date")

    out_of_range_dates.map { |date| date.strftime("%m/%d/%Y") }
  end

  def validate_ro_non_availability_dates
    incorrectly_formatted_ro_dates = filter_incorrectly_formatted_ro_dates
    if incorrectly_formatted_ro_dates.count > 0
      @errors << RoDatesNotCorrectFormat.new(RO_DATES_NOT_CORRECT_FORMAT + incorrectly_formatted_ro_dates.to_s)
    end
    nonunique_ro_dates = filter_nonunique_ro_dates
    if nonunique_ro_dates.count > 0
      @errors << RoDatesNotUnique.new("The following ROs have nonunique dates: " + nonunique_ro_dates.to_s)
    end
    out_of_range_ro_dates = filter_out_of_range_ro_dates
    if out_of_range_ro_dates.count > 0
      @errors << RoDatesNotInRange.new(RO_DATES_NOT_IN_RANGE + out_of_range_ro_dates.to_s)
    end
    @errors << RoListedIncorrectly.new(RO_LISTED_INCORRECTLY) unless validate_ros_with_hearings(@ro_spreadsheet_data)
  end

  def validate_co_non_availability_template
    unless @co_spreadsheet_template[:title] == CO_SPREADSHEET_TITLE &&
           @co_spreadsheet_template[:example_row].compact == CO_SPREADSHEET_EXAMPLE_ROW &&
           @co_spreadsheet_template[:empty_column] == CO_SPREADSHEET_EMPTY_COLUMN
      @errors << CoTemplateNotFollowed.new(CO_TEMPLATE_ERROR)
    end
  end

  def filter_incorrectly_formatted_co_dates
    @co_spreadsheet_data.reject do |date|
      HearingSchedule::DateValidators.new(date).date_correctly_formatted?
    end
  end

  def filter_out_of_co_range_dates
    out_of_range_dates = @co_spreadsheet_data.reject do |date|
      HearingSchedule::DateValidators.new(date, @start_date, @end_date).date_in_range?
    end

    out_of_range_dates.map { |date| date.strftime("%m/%d/%Y") }
  end

  def filter_nonunique_co_dates
    HearingSchedule::UniquenessValidators.new(@co_spreadsheet_data).duplicate_rows.uniq
  end

  def validate_co_non_availability_dates
    incorrectly_formatted_co_dates = filter_incorrectly_formatted_co_dates
    if incorrectly_formatted_co_dates.count > 0
      @errors << CoDatesNotCorrectFormat.new(CO_DATES_NOT_CORRECT_FORMAT + incorrectly_formatted_co_dates.to_s)
    end
    nonunique_co_dates = filter_nonunique_co_dates
    if nonunique_co_dates.count > 0
      @errors << CoDatesNotUnique.new(CO_DATES_NOT_UNIQUE + nonunique_co_dates.to_s)
    end
    out_of_range_co_dates = filter_out_of_co_range_dates
    if out_of_range_co_dates.count > 0
      @errors << CoDatesNotInRange.new(CO_DATES_NOT_IN_RANGE + out_of_range_co_dates.to_s)
    end
  end

  def validate_hearing_allocation_template
    unless @allocation_spreadsheet_template[:title] == HEARING_ALLOCATION_SHEET_TITLE &&
           @allocation_spreadsheet_template[:example_row].compact == HEARING_ALLOCATION_SHEET_EXAMPLE_ROW &&
           @allocation_spreadsheet_template[:empty_column] == HEARING_ALLOCATION_SHEET_EMPTY_COLUMN
      @errors << AllocationTemplateNotFollowed.new(ALLOCATION_TEMPLATE_ERROR)
    end
  end

  def filter_incorrectly_formatted_allocations
    @allocation_spreadsheet_data.reject { |row| row["allocated_days"].is_a?(Numeric) }.pluck("allocated_days")
  end

  def filter_nonunique_allocations
    HearingSchedule::UniquenessValidators.new(@allocation_spreadsheet_data.pluck("ro_code")).duplicate_rows.uniq
  end

  def validate_hearing_allocation_days
    incorrectly_formatted_allocations = filter_incorrectly_formatted_allocations
    if incorrectly_formatted_allocations.count > 0
      @errors << AllocationNotCorrectFormat.new(ALLOCATION_NOT_CORRECT_FORMAT + incorrectly_formatted_allocations.to_s)
    end
    unless validate_ros_with_hearings(@allocation_spreadsheet_data)
      @errors << AllocationRoListedIncorrectly.new(ALLOCATION_LISTED_INCORRECTLY)
    end
    nonunique_allocations = filter_nonunique_allocations
    if nonunique_allocations.count > 0
      @errors << AllocationDuplicateRo.new(ALLOCATION_DUPLICATE_RO + nonunique_allocations.to_s)
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
