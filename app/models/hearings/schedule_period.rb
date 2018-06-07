class SchedulePeriod < ApplicationRecord
  belongs_to :user

  def spreadsheet
    # file = S3Service.fetch_file(file_name, file_path)
    file = '../Documents/wrongDataType.xlsx'
    Roo::Spreadsheet.open(file, extension: :xlsx)
  end
end
