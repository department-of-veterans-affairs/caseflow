# frozen_string_literal: true

module TravelBoardScheduleMapper
  class << self
    def convert_from_vacols_format(travel_board_schedule)
      (travel_board_schedule || []).map do |tb_hearing_day|
        {
          ro: tb_hearing_day[:tbro],
          start_date: tb_hearing_day[:tbstdate],
          end_date: tb_hearing_day[:tbenddate],
          tbmem_1: tb_hearing_day[:tbmem1],
          tbmem_2: tb_hearing_day[:tbmem2],
          tbmem_3: tb_hearing_day[:tbmem3],
          tbmem_4: tb_hearing_day[:tbmem4]
        }
      end
    end
  end
end
