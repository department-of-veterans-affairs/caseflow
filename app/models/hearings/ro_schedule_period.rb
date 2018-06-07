class RoSchedulePeriod < SchedulePeriod
  def validate_spreadsheet
    HearingSchedule::ValidateRoSpreadsheet.new(spreadsheet).validate
  end
end
