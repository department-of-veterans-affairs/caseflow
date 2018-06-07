class JudgeSchedulePeriod < SchedulePeriod
  def validate_spreadsheet
    HearingSchedule::ValidateJudgeSpreadsheet.new(spreadsheet).validate
  end
end
