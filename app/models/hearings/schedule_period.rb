class SchedulePeriod < ApplicationRecord
  belongs_to :user

  def spreadsheet_location
    File.join(Rails.root, "tmp", "hearing_schedule", "spreadsheets", file_name)
  end

  def spreadsheet
    # S3Service.fetch_file(file_name, spreadsheet_location)
    Roo::Spreadsheet.open('spec/support/validJudgeSpreadsheet.xlsx', extension: :xlsx)
  end
end
