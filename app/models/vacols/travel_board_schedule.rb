# Travel Board master schedule is in a table called TBSCHED
class VACOLS::TravelBoardSchedule < VACOLS::Record
  self.table_name = "vacols.tbsched"

  class << self
    def select_tb_with_staff
      # css_id is stored in the STAFF.SDOMAINID column and corresponds to TBSCHED.tbmem1, tbmem2, tbmem3, tbmem4
      select("(TBSCHED.TBYEAR||'-'||TBSCHED.TBTRIP||'-'||TBSCHED.TBLEG) as tbsched_vdkey",
             :tbmem1,
             :tbmem2,
             :tbmem3,
             :tbmem4,
             :tbro,
             :tbstdate,
             :tbenddate,
             :sdomainid)
        .joins(<<-SQL)
        JOIN vacols.staff ON
        staff.sattyid = tbmem1 OR
        staff.sattyid = tbmem2 OR
        staff.sattyid = tbmem3 OR
        staff.sattyid = tbmem4
      SQL
    end

    def hearings_for_judge(css_id)
      id = connection.quote(css_id)

      # css_id is stored in the STAFF.SDOMAINID column and corresponds to TBSCHED.tbmem1, tbmem2, tbmem3, tbmem4
      select_tb_with_staff.where("staff.sdomainid = #{id}")
        .where("tbstdate > ?", 1.year.ago.beginning_of_day)
    end

    def hearing_days_in_date_range(start_date, end_date)
      select_tb_with_staff.where("tbstdate BETWEEN ? AND ?", start_date, end_date)
    end
  end

  def master_record_type
    :travel_board
  end

  def vdkey
    nil
  end
end
