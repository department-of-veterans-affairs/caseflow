FactoryBot.define do
  before(:create) do
    S3Service.store_file("validRoSpreadsheet.xlsx", "spec/support/validRoSpreadsheet.xlsx", :filepath)
  end

  factory :ro_schedule_period do
    start_date { Date.parse("2018-01-01") }
    end_date { Date.parse("2018-06-01") }
    file_name { "validRoSpreadsheet.xlsx" }
    user { create(:user) }
  end
end
