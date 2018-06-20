FactoryBot.define do
  factory :travel_board_schedule, class: VACOLS::TravelBoardSchedule do
    sequence(:tbtrip)

    tbleg true
    tbyear "2018"
    tbro "RO01"
    tbstdate Date.parse("2018-04-30")
    tbenddate Date.parse("2018-05-04")
    tbmem1 { create(:staff, sattyid: 201).sattyid }
  end
end
