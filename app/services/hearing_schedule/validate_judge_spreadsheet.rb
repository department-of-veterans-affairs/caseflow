class HearingSchedule::ValidateJudgeSpreadsheet
  JUDGE_NON_AVAILABILITY_SHEET = 0
  HEADER_COLUMNS = 7
  NAME_COLUMN = 2
  CSS_ID_COLUMN = 3
  DATE_COLUMN = 4

  class JudgeDatesNotCorrectFormat < StandardError; end
  class JudgeTemplateNotFollowed < StandardError; end
  class JudgeDatesNotUnique < StandardError; end
  class JudgeDatesNotInRange < StandardError; end
  class JudgeNotInDb < StandardError; end

  def initialize(spreadsheet, start_date, end_date)
    @spreadsheet = spreadsheet
    @start_date = start_date
    @end_date = end_date
  end

  def judge_non_availability_template
    @spreadsheet.sheet(JUDGE_NON_AVAILABILITY_SHEET)
  end

  def judge_non_availability_dates
    names = judge_non_availability_template.column(NAME_COLUMN).drop(HEADER_COLUMNS)
    css_ids = judge_non_availability_template.column(CSS_ID_COLUMN).drop(HEADER_COLUMNS)
    dates = judge_non_availability_template.column(DATE_COLUMN).drop(HEADER_COLUMNS)
    names.zip(css_ids, dates)
  end

  def validate_judge_non_availability_template
    unless judge_non_availability_template.column(1)[0] == "Judge Non-Availability Dates" &&
        judge_non_availability_template.row(7).uniq == [nil, "Jones, Bernard", "BVAJONESB", Date.parse("02/04/2019")] &&
        judge_non_availability_template.column(5).uniq == [nil]
      fail JudgeTemplateNotFollowed
    end
  end

  def validate_judge_non_availability_dates
    unless judge_non_availability_dates.all? { |date| date[2].instance_of?(Date) }
      fail JudgeDatesNotCorrectFormat
    end
    unless judge_non_availability_dates.uniq == judge_non_availability_dates
      fail JudgeDatesNotUnique
    end
    unless judge_non_availability_dates.all? { |date| date[2] > @start_date && date[2] < @end_date }
      fail JudgeDatesNotInRange
    end
    unless judge_non_availability_dates.all? do |date|
             User.where(css_id: date[1], full_name: date[0].split(", ").reverse.join(" ")).count > 0
           end
      fail JudgeNotInDb
    end
    true
  end

  def validate
    validate_judge_non_availability_template
    validate_judge_non_availability_dates
  end
end
