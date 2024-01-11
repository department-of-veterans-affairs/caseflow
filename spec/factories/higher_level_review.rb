# frozen_string_literal: true

FactoryBot.define do
  factory :higher_level_review do
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

    after(:build) do |hlr, evaluator|
      if evaluator.veteran
        hlr.veteran_file_number = evaluator.veteran.file_number
      end
    end

    after(:create) do |hlr, evaluator|
      payee_code = ClaimantValidator::BENEFIT_TYPE_REQUIRES_PAYEE_CODE.include?(hlr.benefit_type) ? "00" : nil

      if !evaluator.claimants.empty?
        evaluator.claimants.each do |claimant|
          claimant.decision_review = hlr
          claimant.save!
        end
      elsif evaluator.claimant_type
        case evaluator.claimant_type
        when :dependent_claimant
          claimants_to_create = evaluator.number_of_claimants || 1

          create_list(
            :claimant,
            claimants_to_create,
            decision_review: hlr,
            type: "DependentClaimant",
            # there was previously a HLR created in seeds/intake with payee_code "10", this covers that scenario
            payee_code: "10"
          )
        when :attorney_claimant
          create(
            :claimant,
            :attorney,
            participant_id: hlr.veteran.participant_id,
            decision_review: hlr,
            payee_code: payee_code
          )
        when :healthcare_claimant
          create(
            :claimant,
            :with_unrecognized_appellant_detail,
            participant_id: hlr.veteran.participant_id,
            decision_review: hlr,
            type: "HealthcareProviderClaimant",
            payee_code: payee_code
          )
        when :other_claimant
          create(
            :claimant,
            :with_unrecognized_appellant_detail,
            participant_id: hlr.veteran.participant_id,
            decision_review: hlr,
            type: "OtherClaimant",
            payee_code: payee_code
          )
        when :veteran_claimant
          hlr.update!(veteran_is_not_claimant: false)
          create(
            :claimant,
            participant_id: hlr.veteran.participant_id,
            decision_review: hlr,
            payee_code: payee_code,
            type: "VeteranClaimant"
          )
        end
      elsif !Claimant.exists?(participant_id: hlr.veteran.participant_id, decision_review: hlr)
        hlr.update!(veteran_is_not_claimant: false)
        create(
          :claimant,
          participant_id: hlr.veteran.participant_id,
          decision_review: hlr,
          payee_code: payee_code,
          type: "VeteranClaimant"
        )
      end
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

    trait :with_request_issue do
      after(:create) do |hlr, evaluator|
        create(:request_issue,
               benefit_type: hlr.benefit_type,
               nonrating_issue_category: Constants::ISSUE_CATEGORIES[hlr.benefit_type].sample,
               nonrating_issue_description: "#{hlr.business_line.name} Seeded issue",
               decision_review: hlr,
               decision_date: 1.month.ago)

        if evaluator.veteran
          hlr.veteran_file_number = evaluator.veteran.file_number
          hlr.save
        end
      end
    end

    trait :with_vha_issue do
      benefit_type { "vha" }
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

    trait :create_business_line do
      after(:create) do |hlr|
        hlr.submit_for_processing!
        hlr.create_business_line_tasks!
      end
    end
  end
end
