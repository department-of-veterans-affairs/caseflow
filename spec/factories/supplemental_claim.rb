# frozen_string_literal: true

FactoryBot.define do
  factory :supplemental_claim do
    veteran_file_number { generate :veteran_file_number }
    receipt_date { 1.month.ago }
    benefit_type { "compensation" }
    uuid { SecureRandom.uuid }
    veteran_is_not_claimant { true }

    transient do
      number_of_claimants { nil }
    end

    transient do
      claimant_type { :none }
    end

    transient do
      veteran do
        Veteran.find_by(file_number: veteran_file_number) ||
          create(:veteran, file_number: (generate :veteran_file_number))
      end
    end

    after(:build) do |sc, evaluator|
      if evaluator.veteran
        sc.veteran_file_number = evaluator.veteran.file_number
      end
    end

    after(:create) do |sc, evaluator|
      payee_code = ClaimantValidator::BENEFIT_TYPE_REQUIRES_PAYEE_CODE.include?(sc.benefit_type) ? "00" : nil

      if !evaluator.claimants.empty?
        evaluator.claimants.each do |claimant|
          claimant.decision_review = sc
          claimant.save
        end
      elsif evaluator.claimant_type
        case evaluator.claimant_type
        when :dependent_claimant
          claimants_to_create = evaluator.number_of_claimants || 1

          create_list(
            :claimant,
            claimants_to_create,
            decision_review: sc,
            type: "DependentClaimant",
            # there was previously a HLR created in seeds/intake with payee_code "10", this covers that scenario
            payee_code: "10"
          )
        when :attorney_claimant
          create(
            :claimant,
            :attorney,
            participant_id: sc.veteran.participant_id,
            decision_review: sc,
            payee_code: payee_code
          )
        when :healthcare_claimant
          create(
            :claimant,
            :with_unrecognized_appellant_detail,
            participant_id: sc.veteran.participant_id,
            decision_review: sc,
            type: "HealthcareProviderClaimant",
            payee_code: payee_code
          )
        when :other_claimant
          create(
            :claimant,
            :with_unrecognized_appellant_detail,
            participant_id: sc.veteran.participant_id,
            decision_review: sc,
            type: "OtherClaimant",
            payee_code: payee_code
          )
        when :veteran_claimant
          sc.update!(veteran_is_not_claimant: false)
          create(
            :claimant,
            participant_id: sc.veteran.participant_id,
            decision_review: sc,
            payee_code: payee_code,
            type: "VeteranClaimant"
          )
        end
      elsif !Claimant.exists?(participant_id: sc.veteran.participant_id, decision_review: sc)
        sc.update!(veteran_is_not_claimant: false)
        create(
          :claimant,
          participant_id: sc.veteran.participant_id,
          decision_review: sc,
          payee_code: payee_code,
          type: "VeteranClaimant"
        )
      end
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

    trait :with_request_issue do
      after(:create) do |sc, evaluator|
        create(:request_issue,
               benefit_type: sc.benefit_type,
               nonrating_issue_category: Constants::ISSUE_CATEGORIES[sc.benefit_type].sample,
               nonrating_issue_description: "#{sc.business_line.name} Seeded issue",
               decision_review: sc,
               decision_date: 1.month.ago)

        if evaluator.veteran
          sc.veteran_file_number = evaluator.veteran.file_number
          sc.save
        end
      end
    end

    trait :with_vha_issue do
      benefit_type { "vha" }
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
      establishment_submitted_at { Time.zone.now }
      establishment_last_submitted_at { Time.zone.now }
      establishment_processed_at { Time.zone.now }
    end

    trait :requires_processing do
      establishment_submitted_at { (HigherLevelReview.processing_retry_interval_hours + 1).hours.ago }
      establishment_last_submitted_at { (HigherLevelReview.processing_retry_interval_hours + 1).hours.ago }
      establishment_processed_at { nil }
    end
  end
end
