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
    def hearings_for_judge_before_hearing_prep_cutoff_date(css_id)
      id = connection.quote(css_id)

      # css_id is stored in the STAFF.SDOMAINID column and corresponds to TBSCHED.tbmem1, tbmem2, tbmem3, tbmem4
      select("(TBSCHED.TBYEAR||'-'||TBSCHED.TBTRIP||'-'||TBSCHED.TBLEG) as tbsched_vdkey",
             :tbmem1,
             :tbmem2,
             :tbmem3,
             :tbmem4,
             :tbro,
             :tbstdate,
             :tbenddate)
        .joins("join staff on
                staff.sattyid = tbmem1 OR
                staff.sattyid = tbmem2 OR
                staff.sattyid = tbmem3 OR
                staff.sattyid = tbmem4")
        .where("staff.sdomainid = #{id}")
        .where("tbstdate > ?", 1.year.ago.beginning_of_day)
        .where("tbstdate < ?", Date.new(2019, 5, 19).beginning_of_day)
    end

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
