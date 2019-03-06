# frozen_string_literal: true

module TravelBoardScheduleMapper
  class << self
    def convert_from_vacols_format(travel_board_schedule)
      (travel_board_schedule || []).map do |tb_master_record|
        {
          ro: tb_master_record[:tbro],
          start_date: tb_master_record[:tbstdate],
          end_date: tb_master_record[:tbenddate],
          tbmem_1: tb_master_record[:tbmem1],
          tbmem_2: tb_master_record[:tbmem2],
          tbmem_3: tb_master_record[:tbmem3],
          tbmem_4: tb_master_record[:tbmem4]
        }
      end
    end
  end
end
