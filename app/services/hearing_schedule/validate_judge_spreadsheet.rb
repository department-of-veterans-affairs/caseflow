class HearingSchedule::ValidateJudgeSpreadsheet
  SPREADSHEET_TITLE = "Judge Non-Availability Dates".freeze
  SPREADSHEET_EXAMPLE_ROW = [nil, "Jones, Bernard", "123", Date.parse("02/04/2019")].freeze
  SPREADSHEET_EMPTY_COLUMN = [nil].freeze

  class JudgeDatesNotCorrectFormat < StandardError; end
  class JudgeTemplateNotFollowed < StandardError; end
  class JudgeDatesNotUnique < StandardError; end
  class JudgeDatesNotInRange < StandardError; end
  class JudgeNotInDatabase < StandardError; end

  def initialize(spreadsheet, start_date, end_date)
    get_spreadsheet_data = HearingSchedule::GetSpreadsheetData.new(spreadsheet)
    @errors = []
    @spreadsheet_template = get_spreadsheet_data.judge_non_availability_template
    @spreadsheet_data = get_spreadsheet_data.judge_non_availability_data
    @start_date = start_date
    @end_date = end_date
  end

  def validate_judge_non_availability_template
    unless @spreadsheet_template[:title] == SPREADSHEET_TITLE &&
           @spreadsheet_template[:example_row] == SPREADSHEET_EXAMPLE_ROW &&
           @spreadsheet_template[:empty_column] == SPREADSHEET_EMPTY_COLUMN
      @errors << JudgeTemplateNotFollowed
    end
  end

  def judge_in_vacols?(vacols_judges, name, vlj_id)
    vacols_judges[vlj_id] &&
      vacols_judges[vlj_id][:first_name] == name.split(", ")[1] &&
      vacols_judges[vlj_id][:last_name] == name.split(", ")[0]
  end

  def check_range_of_dates(date)
    !date.instance_of?(Date) || (date >= @start_date && date <= @end_date)
  end

  def validate_judge_non_availability_dates
    vacols_judges = User.css_ids_by_vlj_ids(@spreadsheet_data.pluck("vlj_id"))
    unless @spreadsheet_data.all? { |row| row["date"].instance_of?(Date) }
      @errors << JudgeDatesNotCorrectFormat
    end
    unless @spreadsheet_data.uniq == @spreadsheet_data
      @errors << JudgeDatesNotUnique
    end
    unless @spreadsheet_data.all? { |row| check_range_of_dates(row["date"]) }
      @errors << JudgeDatesNotInRange
    end
    unless @spreadsheet_data.all? { |row| judge_in_vacols?(vacols_judges, row["name"], row["vlj_id"]) }
      @errors << JudgeNotInDatabase
    end
  end

  def validate
    validate_judge_non_availability_template
    validate_judge_non_availability_dates
    @errors
  end
end
