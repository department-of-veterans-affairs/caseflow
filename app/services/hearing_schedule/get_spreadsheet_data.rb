class HearingSchedule::GetSpreadsheetData
  JUDGE_NON_AVAILABILITY_SHEET = 0
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
      example_row: judge_non_availability_sheet.row(7).uniq,
      empty_column: judge_non_availability_sheet.column(5).uniq
    }
  end

  def judge_non_availability_data
    non_availability_dates = []
    names = judge_non_availability_sheet.column(2).drop(JUDGE_NON_AVAILABILITY_HEADER_COLUMNS)
    css_ids = judge_non_availability_sheet.column(3).drop(JUDGE_NON_AVAILABILITY_HEADER_COLUMNS)
    dates = judge_non_availability_sheet.column(4).drop(JUDGE_NON_AVAILABILITY_HEADER_COLUMNS)
    names.zip(css_ids, dates).each do |row|
      non_availability_dates.push("name" => row[0], "css_id" => row[1], "date" => row[2])
    end
    non_availability_dates
  end
end
