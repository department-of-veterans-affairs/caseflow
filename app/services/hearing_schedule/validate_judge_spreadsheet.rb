class HearingSchedule::ValidateJudgeSpreadsheet
  JUDGE_NON_AVAILABILITY_SHEET = 0

  class JudgeDatesNotCorrectFormat < StandardError; end
  class JudgeTemplateNotFollowed < StandardError; end
  class JudgeDatesNotUnique < StandardError; end

  def initialize(spreadsheet, start_date, end_date)
    @spreadsheet = spreadsheet
    @start_date = start_date
    @end_date = end_date
  end

  def judge_non_availability_template
    @spreadsheet.sheet(JUDGE_NON_AVAILABILITY_SHEET)
  end

  def judge_non_availability_dates
    judge_non_availability_template.each_row_streaming(offset: 7)
  end

  def validate_judge_non_availability_template
    unless judge_non_availability_template.column(1)[0] == "Judge Non-Availability Dates"
      fail JudgeTemplateNotFollowed
    end
  end

  def validate_judge_non_availability_dates
    unless judge_non_availability_dates { |row| row[2].instance_of?(Date) }
      fail JudgeDatesNotCorrectFormat
    end
    true
  end

  def validate
    validate_judge_non_availability_template
    validate_judge_non_availability_dates
  end
end
