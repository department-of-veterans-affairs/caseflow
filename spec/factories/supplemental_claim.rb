# frozen_string_literal: true

FactoryBot.define do
  factory :supplemental_claim do
    veteran_file_number { generate :veteran_file_number }
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

    trait :with_vha_issue do
      after(:create) do |supplemental_claim, evaluator|
        create(:request_issue,
               benefit_type: "vha",
               nonrating_issue_category: "Beneficiary Travel",
               nonrating_issue_description: "VHA issue description ",
               decision_review: supplemental_claim,
               decision_date: 1.month.ago)

        if evaluator.veteran
          supplemental_claim.veteran_file_number = evaluator.veteran.file_number
          supplemental_claim.save
        end
      end
    end

    trait :processed do
      establishment_processed_at { Time.zone.now }
    end

    transient do
      veteran do
        Veteran.find_by(file_number: veteran_file_number) ||
          create(:veteran, file_number: (generate :veteran_file_number))
      end
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
