# frozen_string_literal: true

FactoryBot.define do
  factory :ramp_election do
    veteran_file_number { generate :vet_file_num }
    receipt_date { 1.month.ago }

    trait :established do
      established_at { Time.zone.now }
    end
  end
end
