FactoryBot.define do
  factory :ramp_election do
    sequence(:veteran_file_number, &:to_s)
    receipt_date { 1.month.ago }
  end
end
