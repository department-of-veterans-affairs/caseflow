# frozen_string_literal: true

class HearingSchedule::AssignJudgesToHearingDays
  class << self
    def load_spreadsheet_data(file_name)
      spreadsheet_location = File.join(Rails.root, "tmp", "hearing_schedule", "spreadsheets", file_name)
      s3_file_location = SchedulePeriod::S3_SUB_BUCKET + "/" + file_name

      S3Service.fetch_file(s3_file_location, spreadsheet_location)
      spreadsheet = Roo::Spreadsheet.open(spreadsheet_location, extension: :xlsx)

      HearingSchedule::GetSpreadsheetData.new(spreadsheet)
    end

    def stage_assignments(spreadsheet_data)
      validate_spreadsheet = HearingSchedule::ValidateJudgeSpreadsheet.new(spreadsheet_data)
      errors = validate_spreadsheet.validate
      if errors.count > 0
        errors.each { |error| fail error }
      end

      hearing_days = ::HearingDay.where(id: spreadsheet_data.judge_assignments.pluck(:hearing_day_id))

      hearing_days.map do |hearing_day|
        data = spreadsheet_data.judge_assignments.find { |day| day[:hearing_day_id] == hearing_day.id }
        result = hearing_day.to_hash
        result[:judge_css_id] = data[:judge_css_id]
        result[:judge_name] = data[:name]
        result
      end
    end

    def confirm_assignments(hearing_days)
      ActiveRecord::Base.transaction do
        begin
          hearing_days.each do |day|
            hearing_day = ::HearingDay.find(day["hearing_day_id"])
            hearing_day.update(judge: User.find_by_css_id(day["judge_css_id"]))
          end
        rescue StandardError
          raise ActiveRecord::Rollback
        end
      end
    end
  end
end
