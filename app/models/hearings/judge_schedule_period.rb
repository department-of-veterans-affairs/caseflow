class JudgeSchedulePeriod < SchedulePeriod
  def validate_spreadsheet
    HearingSchedule::ValidateJudgeSpreadsheet.new(spreadsheet, start_date, end_date).validate
  end
end
