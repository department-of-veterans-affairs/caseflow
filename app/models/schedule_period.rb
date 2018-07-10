class SchedulePeriod < ApplicationRecord
  belongs_to :user
  has_many :allocations

  delegate :full_name, to: :user, prefix: true

  def spreadsheet_location
    File.join(Rails.root, "tmp", "hearing_schedule", "spreadsheets", file_name)
  end

  def spreadsheet
    S3Service.fetch_file(file_name, spreadsheet_location)
    Roo::Spreadsheet.open(spreadsheet_location, extension: :xlsx)
  end

  def to_hash
    serializable_hash(
      methods: [:user_full_name, :type]
    )
  end
end
