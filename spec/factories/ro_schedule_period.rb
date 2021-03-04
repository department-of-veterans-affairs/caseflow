# frozen_string_literal: true

FactoryBot.define do
  before(:create) do
    S3Service.store_file(SchedulePeriod::S3_SUB_BUCKET + "/" + "invalidRoSpreadsheet.xlsx",
                         "spec/support/invalidRoSpreadsheet.xlsx", :filepath)
    S3Service.store_file(SchedulePeriod::S3_SUB_BUCKET + "/" + "validRoSpreadsheet.xlsx",
                         "spec/support/validRoSpreadsheet.xlsx", :filepath)
    S3Service.store_file(SchedulePeriod::S3_SUB_BUCKET + "/" + "blankRoSpreadsheet.xlsx",
                         "spec/support/blankRoSpreadsheet.xlsx", :filepath)
  end

  factory :ro_schedule_period do
    start_date { Date.parse("2018-01-01") }
    end_date { Date.parse("2018-06-01") }
    file_name { "validRoSpreadsheet.xlsx" }
    user

    factory :invalid_ro_schedule_period do
      start_date { Date.parse("2021-04-01") }
      end_date { Date.parse("2021-06-30") }
      file_name { "invalidRoSpreadsheet.xlsx" }
      user
    end

    factory :blank_ro_schedule_period do
      start_date { Date.parse("2018-01-01") }
      end_date { Date.parse("2018-06-01") }
      file_name { "blankRoSpreadsheet.xlsx" }
      user
    end
  end
end
