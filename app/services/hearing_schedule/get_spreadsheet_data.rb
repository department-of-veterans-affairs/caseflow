# frozen_string_literal: true

class HearingSchedule::GetSpreadsheetData
  JUDGE_NON_AVAILABILITY_SHEET = 0
  RO_NON_AVAILABILITY_SHEET = 0
  CO_NON_AVAILABILITY_SHEET = 1
  HEARING_ALLOCATION_SHEET = 2
  HEARING_ALLOCATION_SHEET_EXAMPLE_ROW = 4
  JUDGE_NON_AVAILABILITY_HEADER_COLUMNS = 7

  def initialize(spreadsheet)
    @spreadsheet = spreadsheet
  end

  def judge_non_availability_sheet
    @spreadsheet.sheet(JUDGE_NON_AVAILABILITY_SHEET)
  end

  def judge_non_availability_template
    {
      title: judge_non_availability_sheet.column(1)[0],
      headers: judge_non_availability_sheet.row(2).uniq,
      empty_column: judge_non_availability_sheet.column(5).uniq
    }
  end

  def judge_non_availability_data
    non_availability_dates = []
    names = judge_non_availability_sheet.column(2).drop(JUDGE_NON_AVAILABILITY_HEADER_COLUMNS)
    vlj_ids = judge_non_availability_sheet.column(3).drop(JUDGE_NON_AVAILABILITY_HEADER_COLUMNS)
    dates = judge_non_availability_sheet.column(4).drop(JUDGE_NON_AVAILABILITY_HEADER_COLUMNS)
    names.zip(vlj_ids, dates).each do |row|
      non_availability_dates.push("name" => row[0].strip, "vlj_id" => row[1].to_s.strip, "date" => row[2])
    end
    non_availability_dates
  end

  def ro_non_availability_sheet
    @spreadsheet.sheet(RO_NON_AVAILABILITY_SHEET)
  end

  def ro_non_availability_template
    {
      title: ro_non_availability_sheet.row(1)[2],
      example_row: ro_non_availability_sheet.column(2).uniq,
      empty_column: ro_non_availability_sheet.column(60).uniq
    }
  end

  def ro_non_availability_data
    non_availability_dates = []
    ro_codes = ro_non_availability_sheet.row(2).drop(2)
    ro_names = ro_non_availability_sheet.row(3).drop(2)
    ro_codes.zip(ro_names).each_with_index do |row, index|
      dates = ro_non_availability_sheet.column(index + 3).drop(3).compact
      dates.each do |date|
        # Get the RO city/state accounting for the Nation Virtual Hearings Queue
        ro_city = get_ro_city_state(row[0].strip, row[1])[0]
        ro_state = get_ro_city_state(row[0].strip, row[1])[1]

        non_availability_dates.push("ro_code" => row[0].strip,
                                    "ro_city" => ro_city,
                                    "ro_state" => ro_state,
                                    "date" => date)
      end
    end
    non_availability_dates
  end

  def co_non_availability_sheet
    @spreadsheet.sheet(CO_NON_AVAILABILITY_SHEET)
  end

  def co_non_availability_template
    {
      title: co_non_availability_sheet.row(1)[0],
      example_row: co_non_availability_sheet.row(3).uniq,
      empty_column: co_non_availability_sheet.column(3).uniq
    }
  end

  def co_non_availability_data
    co_non_availability_sheet.column(2).drop(3)
  end

  def allocation_sheet
    @spreadsheet.sheet(HEARING_ALLOCATION_SHEET)
  end

  def allocation_template
    {
      title: allocation_sheet.row(1)[0],
      example_row: allocation_sheet.row(HEARING_ALLOCATION_SHEET_EXAMPLE_ROW).uniq,
      empty_column: allocation_sheet.column(9).uniq
    }
  end

  def allocation_data
    # Instantiate the hearing allocation days to be filled by data from the spreadsheet
    hearing_allocation_days = []

    # Extract the RO Name, Code, allocated days and Virtual Hearing Days
    ro_names = allocation_sheet.column(2).drop(HEARING_ALLOCATION_SHEET_EXAMPLE_ROW)
    ro_codes = allocation_sheet.column(3).drop(HEARING_ALLOCATION_SHEET_EXAMPLE_ROW)
    allocated_days = allocation_sheet.column(4).drop(HEARING_ALLOCATION_SHEET_EXAMPLE_ROW)
    allocated_days_without_room = allocation_sheet.column(5).drop(HEARING_ALLOCATION_SHEET_EXAMPLE_ROW)
    number_of_slots = allocation_sheet.column(6).drop(HEARING_ALLOCATION_SHEET_EXAMPLE_ROW)
    slot_length_minutes = allocation_sheet.column(7).drop(HEARING_ALLOCATION_SHEET_EXAMPLE_ROW)
    first_slot_time = allocation_sheet.column(8).drop(HEARING_ALLOCATION_SHEET_EXAMPLE_ROW)

    # Combine the parse spreadsheet data
    parsed_data = ro_names.zip(
      ro_codes,
      allocated_days,
      allocated_days_without_room,
      number_of_slots,
      slot_length_minutes,
      first_slot_time
    )

    # Map the data to the hearing allocation days
    parsed_data.each do |row|
      # Get the RO city/state accounting for the Nation Virtual Hearings Queue
      ro_city = get_ro_city_state(row[1].strip, row[0])[0]
      ro_state = get_ro_city_state(row[1].strip, row[0])[1]
      hearing_allocation_days.push(
        "ro_code" => row[1].strip,
        "ro_city" => ro_city,
        "ro_state" => ro_state,
        "allocated_days" => row[2],
        "allocated_days_without_room" => row[3],
        "number_of_slots" => row[4],
        "slot_length_minutes" => row[5],
        "first_slot_time" => row[6]
      )
    end

    # Return the list of allocated hearing days
    hearing_allocation_days
  end

  private

  def get_ro_city_state(ro_key, ro_location)
    if ro_key == "NVHQ"
      []
    else
      ro_location.split(", ").map(&:strip)
    end
  end
end
