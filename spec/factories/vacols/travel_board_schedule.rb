# frozen_string_literal: true

FactoryBot.define do
  factory :travel_board_schedule, class: VACOLS::TravelBoardSchedule do
    sequence(:tbtrip)

    tbleg { true }
    tbyear { "2018" }
    tbro { "RO17" }
    tbstdate { Date.parse("2018-05-07") }
    tbenddate { Date.parse("2018-05-11") }
    tbmem1 { create(:staff, sattyid: 201).sattyid }
  end

  factory :july_travel_board_schedule, class: VACOLS::TravelBoardSchedule do
    sequence(:tbtrip)

    tbleg { true }
    tbyear { "2018" }
    tbro { "RO17" }
    tbstdate { Date.parse("2018-07-30") }
    tbenddate { Date.parse("2018-08-03") }
    tbmem1 { create(:staff, sattyid: 861).sattyid }
  end
end
