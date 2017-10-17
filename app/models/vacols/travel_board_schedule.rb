# Travel Board master schedule is in a table called TBSCHED
class VACOLS::TravelBoardSchedule < VACOLS::Record
  self.table_name = "vacols.tbsched"

  class << self
    def upcoming_for_judge(css_id)
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
        .where("tbstdate > ?", 1.week.ago)
    end
  end

  def master_record_type
    :travel_board
  end

  def vdkey
    nil
  end
end
