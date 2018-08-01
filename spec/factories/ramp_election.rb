FactoryBot.define do
  factory :ramp_election do
    sequence(:veteran_file_number, &:to_s)
    receipt_date { 1.month.ago }

    trait :established do
      established_at Time.zone.now
    end
  end
end
