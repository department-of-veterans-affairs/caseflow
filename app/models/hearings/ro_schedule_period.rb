class RoSchedulePeriod < SchedulePeriod
  def validate_spreadsheet
    HearingSchedule::ValidateRoSpreadsheet.new(spreadsheet, start_date, end_date).validate
  end
end
