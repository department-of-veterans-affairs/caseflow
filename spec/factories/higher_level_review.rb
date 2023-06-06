# frozen_string_literal: true

FactoryBot.define do
  factory :higher_level_review do
    veteran_file_number { generate :veteran_file_number }
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

    trait :with_vha_issue do
      after(:create) do |higher_level_review, evaluator|
        create(:request_issue,
               benefit_type: "vha",
               nonrating_issue_category: "Caregiver | Other",
               nonrating_issue_description: "VHA - Caregiver ",
               decision_review: higher_level_review,
               decision_date: 1.month.ago)

        if evaluator.veteran
          higher_level_review.veteran_file_number = evaluator.veteran.file_number
          higher_level_review.save
        end
      end
    end

    transient do
      veteran do
        Veteran.find_by(file_number: veteran_file_number) ||
          create(:veteran, file_number: (generate :veteran_file_number))
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

    trait :create_business_line do
      after(:create) do |hlr|
        hlr.submit_for_processing!
        hlr.create_business_line_tasks!
      end
    end

    after(:create) do |hlr, evaluator|
      if evaluator.number_of_claimants
        create_list(
          :claimant,
          evaluator.number_of_claimants,
          decision_review: hlr,
          payee_code: "00",
          type: "VeteranClaimant"
        )
      end
    end
  end
end
