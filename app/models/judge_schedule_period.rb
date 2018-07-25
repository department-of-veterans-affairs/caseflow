class JudgeSchedulePeriod < SchedulePeriod
  validate :validate_spreadsheet, on: :create
  after_create :import_spreadsheet

  def validate_spreadsheet
    validate_spreadsheet = HearingSchedule::ValidateJudgeSpreadsheet.new(spreadsheet, start_date, end_date)
    errors[:base] << validate_spreadsheet.validate
  end

  def import_spreadsheet
    JudgeNonAvailability.import_judge_non_availability(self)
  end

  def schedule_confirmed(hearing_schedule)
    HearingDay.update_schedule(hearing_schedule)
    super
  end
end
