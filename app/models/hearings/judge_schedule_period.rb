class JudgeSchedulePeriod < SchedulePeriod
  def validate_spreadsheet
    HearingSchedule::ValidateJudgeSpreadsheet.validate(spreadsheet)
  end
end
