class HearingSchedule::ValidateJudgeSpreadsheet

  def initialize(spreadsheet, start_date, end_date)
    @spreadsheet = spreadsheet
    @start_date = start_date
    @end_date = end_date
  end

  def validate
    true
  end
end
