# frozen_string_literal: true

FactoryBot.define do
  factory :judge_schedule_period do
    start_date { Date.parse("2018-04-01") }
    end_date { Date.parse("2018-09-30") }
    file_name { "validJudgeSpreadsheet.xlsx" }
    user { create(:default_user) }

    factory :blank_judge_schedule_period do
      start_date { Date.parse("2018-01-01") }
      end_date { Date.parse("2018-06-01") }
      file_name { "blankJudgeSpreadsheet.xlsx" }
      user { create(:user) }
    end

    factory :single_nonavail_date_judge_schedule_period do
      start_date { Date.parse("2018-07-29") }
      end_date { Date.parse("2018-08-04") }
      file_name { "singleNonAvailJudgeSpreadsheet.xlsx" }
      user { create(:user) }
    end

    factory :two_in_july_judge_schedule_period do
      start_date { Date.parse("2018-07-29") }
      end_date { Date.parse("2018-08-04") }
      file_name { "twoInJulyJudgeSpreadsheet.xlsx" }
      user { create(:user) }
    end

    factory :one_month_judge_schedule_period do
      start_date { Date.parse("2018-07-22") }
      end_date { Date.parse("2018-08-18") }
      file_name { "oneAllAvailJudgeSpreadsheet.xlsx" }
      user { create(:user) }
    end

    factory :one_month_two_judge_schedule_period do
      start_date { Date.parse("2018-07-22") }
      end_date { Date.parse("2018-08-18") }
      file_name { "twoAllAvailJudgeSpreadsheet.xlsx" }
      user { create(:user) }
    end

    factory :one_month_many_noavail_judge_schedule_period do
      start_date { Date.parse("2018-07-22") }
      end_date { Date.parse("2018-08-18") }
      file_name { "manyNonAvailJudgeSpreadsheet.xlsx" }
      user { create(:user) }
    end

    factory :one_week_one_judge_schedule_period do
      start_date { Date.parse("2018-07-29") }
      end_date { Date.parse("2018-08-04") }
      file_name { "oneAllAvailJudgeSpreadsheet.xlsx" }
      user { create(:user) }
    end

    factory :one_week_two_judge_schedule_period do
      start_date { Date.parse("2018-07-29") }
      end_date { Date.parse("2018-08-04") }
      file_name { "twoAllAvailJudgeSpreadsheet.xlsx" }
      user { create(:user) }
    end

    before(:create) do
      S3Service.store_file(SchedulePeriod::S3_SUB_BUCKET + "/" + "validJudgeSpreadsheet.xlsx",
                           "spec/support/validJudgeSpreadsheet.xlsx", :filepath)
      S3Service.store_file(SchedulePeriod::S3_SUB_BUCKET + "/" + "blankJudgeSpreadsheet.xlsx",
                           "spec/support/blankJudgeSpreadsheet.xlsx", :filepath)
      S3Service.store_file(SchedulePeriod::S3_SUB_BUCKET + "/" + "singleNonAvailJudgeSpreadsheet.xlsx",
                           "spec/support/singleNonAvailJudgeSpreadsheet.xlsx", :filepath)
      S3Service.store_file(SchedulePeriod::S3_SUB_BUCKET + "/" + "twoInJulyJudgeSpreadsheet.xlsx",
                           "spec/support/twoInJulyJudgeSpreadsheet.xlsx", :filepath)
      S3Service.store_file(SchedulePeriod::S3_SUB_BUCKET + "/" + "oneAllAvailJudgeSpreadsheet.xlsx",
                           "spec/support/oneAllAvailJudgeSpreadsheet.xlsx", :filepath)
      S3Service.store_file(SchedulePeriod::S3_SUB_BUCKET + "/" + "manyNonAvailJudgeSpreadsheet.xlsx",
                           "spec/support/manyNonAvailJudgeSpreadsheet.xlsx", :filepath)
      S3Service.store_file(SchedulePeriod::S3_SUB_BUCKET + "/" + "twoAllAvailJudgeSpreadsheet.xlsx",
                           "spec/support/twoAllAvailJudgeSpreadsheet.xlsx", :filepath)
      create(:staff, sattyid: "860", snamef: "Stuart", snamel: "Huels")
      create(:staff, sattyid: "861", snamef: "Doris", snamel: "Lamphere")
    end

    after(:create) do |schedule_period|
      create(:staff, :hearing_judge, sdomainid: schedule_period.user.css_id)
    end
  end
end
