class HearingSchedule::ValidateJudgeSpreadsheet
  SPREADSHEET_TITLE = "Judge Non-Availability Dates".freeze
  SPREADSHEET_EXAMPLE_ROW = [nil, "Jones, Bernard", "BVAJONESB", Date.parse("02/04/2019")].freeze
  SPREADSHEET_EMPTY_COLUMN = [nil].freeze

  class JudgeDatesNotCorrectFormat < StandardError; end
  class JudgeTemplateNotFollowed < StandardError; end
  class JudgeDatesNotUnique < StandardError; end
  class JudgeDatesNotInRange < StandardError; end
  class JudgeNotInDatabase < StandardError; end

  def initialize(spreadsheet, start_date, end_date)
    @spreadsheet_template = HearingSchedule::GetSpreadsheetData.new(spreadsheet).judge_non_availability_template
    @spreadsheet_data = HearingSchedule::GetSpreadsheetData.new(spreadsheet).judge_non_availability_data
    @start_date = start_date
    @end_date = end_date
  end

  def validate_judge_non_availability_template
    unless @spreadsheet_template[:title] == SPREADSHEET_TITLE &&
           @spreadsheet_template[:example_row] == SPREADSHEET_EXAMPLE_ROW &&
           @spreadsheet_template[:empty_column] == SPREADSHEET_EMPTY_COLUMN
      fail JudgeTemplateNotFollowed
    end
  end

  def validate_judge_non_availability_dates
    unless @spreadsheet_data.all? { |row| row["date"].instance_of?(Date) }
      fail JudgeDatesNotCorrectFormat
    end
    unless @spreadsheet_data.uniq == @spreadsheet_data
      fail JudgeDatesNotUnique
    end
    unless @spreadsheet_data.all? do |row|
      row["date"] >= @start_date &&
      row["date"] <= @end_date
    end
      fail JudgeDatesNotInRange
    end
    unless @spreadsheet_data.all? do |row|
             User.where(css_id: row["css_id"],
                        full_name: row["name"].split(", ").reverse.join(" ")).count > 0
           end
      fail JudgeNotInDatabase
    end
    true
  end

  def validate
    validate_judge_non_availability_template
    validate_judge_non_availability_dates
  end
end
