FactoryBot.define do
  before(:create) do
    S3Service.store_file("validJudgeSpreadsheet.xlsx", "spec/support/validJudgeSpreadsheet.xlsx", :filepath)
  end

  factory :judge_schedule_period do
    start_date { Date.parse("2018-04-01") }
    end_date { Date.parse("2018-09-30") }
    file_name { "validJudgeSpreadsheet.xlsx" }
    user { create(:default_user) }
  end

  factory :blank_judge_schedule_period do
    start_date { Date.parse("2018-01-01") }
    end_date { Date.parse("2018-06-01") }
    file_name { "blankJudgeSpreadsheet.xlsx" }
    user { create(:user) }
  end
end
