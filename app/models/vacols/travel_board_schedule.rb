# frozen_string_literal: true

# Travel Board master schedule is in a table called TBSCHED
class VACOLS::TravelBoardSchedule < VACOLS::Record
  self.table_name = "vacols.tbsched"

  attribute :tbleg, :integer

  COLUMN_NAMES = {
    tbyear: :tbyear,
    tbtrip: :tbtrip,
    tbleg: :tbleg,
    regional_office: :tbro
  }.freeze

  # :nocov:
  class << self
    def hearings_for_judge(css_id)
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
        .joins("join vacols.staff on
                staff.sattyid = tbmem1 OR
                staff.sattyid = tbmem2 OR
                staff.sattyid = tbmem3 OR
                staff.sattyid = tbmem4")
        .where("staff.sdomainid = #{id}")
        .where("tbstdate > ?", 1.year.ago.beginning_of_day)
    end

    def load_days_for_range(start_date, end_date)
      where("tbstdate BETWEEN ? AND ?", start_date, end_date)
    end

    def load_days_for_regional_office(regional_office, start_date, end_date)
      where("tbro = ? and tbstdate BETWEEN ? AND ?", regional_office, start_date, end_date)
    end
  end

  def update_hearing!(hearing_info)
    attrs = hearing_info.each_with_object({}) { |(k, v), result| result[COLUMN_NAMES[k]] = v }
    attrs.delete(nil)
    MetricsService.record("VACOLS: update_hearing! #{tbyear}-#{tbtrip}-#{tbleg}",
                          service: :vacols,
                          name: "update_hearing") do
      hearings = VACOLS::TravelBoardSchedule.where(tbyear: tbyear, tbtrip: tbtrip, tbleg: tbleg)
      hearings.update_all(attrs.merge(tbmoduser: self.class.current_user_slogid,
                                      tbmodtime: VacolsHelper.local_time_with_utc_timezone))
      hearings[0]
    end
  end

  def master_record_type
    :travel_board
  end

  def vdkey
    nil
  end

  def folder_nr
    :fake_folder_nr
  end
end
