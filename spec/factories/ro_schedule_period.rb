FactoryBot.define do
  factory :ro_schedule_period do
    start_date { Date.parse("2018-01-01") }
    end_date { Date.parse("2018-06-01") }
    file_name { "validRoSpreadsheet.xlsx" }
    user { create(:user) }
  end
end
