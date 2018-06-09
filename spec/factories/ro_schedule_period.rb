FactoryBot.define do
  factory :ro_schedule_period do
    start_date { Date.parse("2018-04-01") }
    end_date { Date.parse("2018-09-30") }
    file_name { "sample_file_name.xlsx" }
    user { create(:user) }
  end
end
