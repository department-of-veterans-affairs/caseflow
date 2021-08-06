# frozen_string_literal: true

##
# JudgeSchedulePeriod represents a schedule period for assigning judges to hearing days.
# This record is created after user uploads JudgeAssignment spreadsheet for a schedule period.
# Once created, it creates JudgeNonAvailability records with the blackout dates for each judge.
#
# This class is no longer used, but preserved here to make it easier to access historical database records.
##
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
    JudgeSchedulePeriod.transaction do
      start_confirming_schedule
      begin
        transaction do
          HearingDay.update_schedule(hearing_schedule)
        end
        super
      rescue StandardError
        end_confirming_schedule
        raise ActiveRecord::Rollback
      end
    end
    end_confirming_schedule
  end

  private

  def assign_judges_to_hearing_schedule
    assign_judges_to_hearing_days = HearingSchedule::AssignJudgesToHearingDays.new(self)
    assign_judges_to_hearing_days.match_hearing_days_to_judges
  end
end
