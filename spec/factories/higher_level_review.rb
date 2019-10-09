# frozen_string_literal: true

FactoryBot.define do
  factory :higher_level_review do
    sequence(:veteran_file_number, &:to_s)
    receipt_date { 1.month.ago }
    benefit_type { "compensation" }
    uuid { SecureRandom.uuid }

    transient do
      number_of_claimants { nil }
    end

    trait :with_end_product_establishment do
      after(:create) do |higher_level_review|
        create(
          :end_product_establishment,
          veteran_file_number: higher_level_review.veteran_file_number,
          source: higher_level_review
        )
      end
    end

    trait :processed do
      establishment_processed_at { Time.zone.now }
    end

    trait :requires_processing do
      establishment_submitted_at { (HigherLevelReview.processing_retry_interval_hours + 1).hours.ago }
      establishment_last_submitted_at { (HigherLevelReview.processing_retry_interval_hours + 1).hours.ago }
      establishment_processed_at { nil }
    end

    after(:create) do |hlr, evaluator|
      if evaluator.number_of_claimants
        hlr.claimants = create_list(:claimant, evaluator.number_of_claimants, decision_review: hlr, payee_code: "00")
      end
    end
  end
end
