FactoryBot.define do
  factory :mail, class: VACOLS::Mail do
    mlcompdate { VacolsHelper.local_date_with_utc_timezone }
    mltype "02"
  end
end

