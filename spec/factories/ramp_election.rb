FactoryBot.define do
  factory :ramp_election do
    sequence(:veteran_file_number) { |n| "#{n}" }
    receipt_date { 1.month.ago }
  end
end
