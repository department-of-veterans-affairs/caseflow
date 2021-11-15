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

    trait :with_end_product_establishment do
      after(:create) do |supplemental_claim|
        create(
          :end_product_establishment,
          veteran_file_number: supplemental_claim.veteran_file_number,
          source: supplemental_claim
        )
      end
    end

    trait :processed do
      establishment_processed_at { Time.zone.now }
    end

    after(:create) do |sc, evaluator|
      if evaluator.number_of_claimants
        create_list(
          :claimant,
          evaluator.number_of_claimants,
          payee_code: "00",
          decision_review: sc,
          type: "VeteranClaimant"
        )
      end
    end
  end
end
