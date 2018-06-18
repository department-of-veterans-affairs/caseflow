module TravelBoardScheduleMapper
  class << self
    def convert_from_vacols_format(travel_board_schedule, fetch_users = false)
      (travel_board_schedule || []).map do |tb_master_record|
        {
          ro:  tb_master_record[:tbro],
          start_date: tb_master_record[:tbstdate],
          end_date: tb_master_record[:tbenddate]
        }.merge(fetch_users ? { travel_board_member: User.where(css_id: tb_master_record[:sdomainid]) } : {})
      end
    end
  end
end
