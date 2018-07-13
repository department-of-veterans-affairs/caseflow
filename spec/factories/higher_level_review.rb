FactoryBot.define do
  factory :higher_level_review do
    sequence(:veteran_file_number, &:to_s)
    receipt_date { 1.month.ago }
  end
end
