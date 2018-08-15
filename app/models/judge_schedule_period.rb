class JudgeSchedulePeriod < SchedulePeriod
  validate :validate_spreadsheet, on: :create
  after_create :import_spreadsheet

  cache_attribute :algorithm_assignments, expires_in: 4.days do
    assign_judges_to_hearing_schedule
  end

  def validate_spreadsheet
    validate_spreadsheet = HearingSchedule::ValidateJudgeSpreadsheet.new(spreadsheet, start_date, end_date)
    errors[:base] << validate_spreadsheet.validate
  end

  def import_spreadsheet
    JudgeNonAvailability.import_judge_non_availability(self)
  end

  def schedule_confirmed(hearing_schedule)
    hearing_days = hearing_schedule.map do |hearing_day|
      hearing_day.slice(:hearing_pkseq, :judge_id)
    end

    transaction do
      HearingDay.update_schedule(hearing_days)
      super
    end
  end

  private

  def assign_judges_to_hearing_schedule
    assign_judges_to_hearing_days = HearingSchedule::AssignJudgesToHearingDays.new(self)
    assign_judges_to_hearing_days.match_hearing_days_to_judges
  end
end
