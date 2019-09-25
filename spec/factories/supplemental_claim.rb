# frozen_string_literal: true

FactoryBot.define do
  factory :supplemental_claim do
    sequence(:veteran_file_number, &:to_s)
    receipt_date { 1.month.ago }
    benefit_type { "compensation" }
    uuid { SecureRandom.uuid }

    transient do
      number_of_claimants { nil }
    end

    trait :processed do
      establishment_processed_at { Time.zone.now }
    end

    after(:create) do |sc, evaluator|
      if evaluator.number_of_claimants
        sc.claimants = create_list(:claimant, evaluator.number_of_claimants, decision_review: sc)
      end
    end
  end
end
