class JudgeSchedulePeriod < SchedulePeriod
  after_create :import_spreadsheet

  def validate_spreadsheet
    HearingSchedule::ValidateJudgeSpreadsheet.new(spreadsheet, start_date, end_date).validate
  end

  def import_spreadsheet
    JudgeNonAvailability.import_judge_non_availability(self)
  end

  def schedule_confirmed(hearing_schedule)
    HearingDay.update_schedule(hearing_schedule)
    super
  end
end
