class SchedulePeriod < ApplicationRecord
  belongs_to :user

  DOWNLOAD_SPREADSHEET_PATH = "/tmp/hearing_schedule/spreadsheets".freeze

  def spreadsheet
    file_path = DOWNLOAD_SPREADSHEET_PATH + file_name
    S3Service.fetch_file(file_name, file_path)
    Roo::Spreadsheet.open(file_path, extension: :xlsx)
  end
end
