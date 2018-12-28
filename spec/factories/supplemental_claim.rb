FactoryBot.define do
  factory :supplemental_claim do
    sequence(:veteran_file_number, &:to_s)
    receipt_date { 1.month.ago }
    benefit_type "compensation"
  end
end
