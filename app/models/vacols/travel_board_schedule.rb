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

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: tbsched
#
#  tbaddtime :date
#  tbadduser :string(16)
#  tbaty1    :string(6)
#  tbaty2    :string(6)
#  tbaty3    :string(6)
#  tbaty4    :string(6)
#  tbbvapoc  :string(40)
#  tbcancel  :string(1)
#  tbenddate :date
#  tbleg     :boolean          not null
#  tbmem1    :string(6)
#  tbmem2    :string(6)
#  tbmem3    :string(6)
#  tbmem4    :string(6)
#  tbmodtime :date
#  tbmoduser :string(16)
#  tbro      :string(16)
#  tbropoc   :string(40)
#  tbstdate  :date
#  tbtrip    :integer          not null
#  tbyear    :string(4)        not null
#
