# frozen_string_literal: true

module HearingsConcerns
  module VerifyAccess
    extend ActiveSupport::Concern

    def verify_access_to_reader_or_hearings
      verify_authorized_roles("Reader", "Hearing Prep", "Edit HearSched", "Build HearSched")
    end

    def verify_edit_worksheet_access
      verify_authorized_roles("Hearing Prep")
    end

    def verify_access_to_hearings
      verify_authorized_roles("Hearing Prep", "Edit HearSched", "Build HearSched", "RO ViewHearSched")
    end

    def verify_build_hearing_schedule_access
      verify_authorized_roles("Build HearSched")
    end

    def verify_edit_hearing_schedule_access
      verify_authorized_roles("Edit HearSched", "Build HearSched")
    end

    def verify_view_hearing_schedule_access
      verify_authorized_roles("Edit HearSched", "Build HearSched", "RO ViewHearSched", "VSO", "Hearing Prep")
    end
  end

  module JudgeAssignment
    def assign_vljs_to_hearing_days(assignments)
      file_name = assignments["file_name"]
      spreadsheet_location = File.join(Rails.root, "tmp", "hearing_schedule", "spreadsheets", file_name)
      s3_file_location = SchedulePeriod::S3_SUB_BUCKET + "/" + file_name

      S3Service.fetch_file(s3_file_location, spreadsheet_location)
      spreadsheet = Roo::Spreadsheet.open(spreadsheet_location, extension: :xlsx)
      spreadsheet_data = HearingSchedule::GetSpreadsheetData.new(spreadsheet)

      validate_spreadsheet = HearingSchedule::ValidateJudgeSpreadsheet.new(spreadsheet_data)
      errors = validate_spreadsheet.validate
      if errors.count > 0
        errors.each { |error| fail error }
      end

      hearing_days = HearingDay.where(id: spreadsheet_data.judge_assignments.pluck(:hearing_day_id))

      hearing_days.map do |hearing_day|
        data = spreadsheet_data.judge_assignments.find { |day| day[:hearing_day_id] == hearing_day.id }
        result = hearing_day.to_hash
        result[:judge_id] = data[:vlj_id].to_i
        result[:judge_name] = data[:name]
        result
      end
    end

    def confirm_assignments(hearing_days)
      ActiveRecord::Base.transaction do
        begin
          hearing_days.each do |day|
            hearing_day = HearingDay.find(day["hearing_day_id"])
            judge = User.find_by_css_id(User.css_ids_by_vlj_ids(day["judge_id"])[day["judge_id"].to_s][:css_id])
            hearing_day.update!(judge: judge)
          end
        rescue StandardError
          raise ActiveRecord::Rollback
        end
      end
    end
  end
end
