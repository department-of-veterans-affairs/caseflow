# frozen_string_literal: true

FactoryBot.define do
  factory :ramp_refiling do
    veteran_file_number { generate :veteran_file_number }
    receipt_date { 1.month.ago }

    trait :established do
      established_at { Time.zone.now }
    end
  end
end
