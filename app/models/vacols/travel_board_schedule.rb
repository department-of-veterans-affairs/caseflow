# frozen_string_literal: true

# Travel Board master schedule is in a table called TBSCHED
class VACOLS::TravelBoardSchedule < VACOLS::Record
  self.table_name = "tbsched"

  attribute :tbleg, :integer

  COLUMN_NAMES = {
    tbyear: :tbyear,
    tbtrip: :tbtrip,
    tbleg: :tbleg,
    regional_office: :tbro
  }.freeze

  # :nocov:
  class << self
    def load_days_for_range(start_date, end_date)
      where("tbstdate BETWEEN ? AND ?", start_date, end_date)
    end
  end

  def vdkey
    nil
  end

  def folder_nr
    :fake_folder_nr
  end
  # :nocov:
end
