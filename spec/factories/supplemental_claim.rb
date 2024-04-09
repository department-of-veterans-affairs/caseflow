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

    transient do
      assigned_at { Time.zone.now }
    end

    transient do
      disposition { nil }
    end

    transient do
      decision_date { nil }
    end

    transient do
      issue_type { nil }
    end

    transient do
      description { nil }
    end

    transient do
      withdraw { false }
    end

    transient do
      remove { false }
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
        when :other_claimant_not_listed
          create(
            :claimant,
            :with_unrecognized_appellant_not_listed_poa,
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

    # creates request issue with issue type and decision date sent as a evaluator
    trait :with_issue_type do
      after(:create) do |sc, evaluator|
        create(:request_issue,
               decision_date: evaluator.decision_date,
               benefit_type: sc.benefit_type,
               nonrating_issue_category: evaluator.issue_type,
               nonrating_issue_description: "#{sc.business_line.name} #{evaluator.description}",
               decision_review: sc)

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

    trait :with_disposition do
      after(:create) do |sc, evaluator|
        create(:decision_issue,
               benefit_type: "vha",
               request_issues: sc.request_issues,
               decision_review: sc,
               disposition: evaluator.disposition,
               caseflow_decision_date: Time.zone.now)
      end
    end

    trait :with_intake do
      after(:create) do |sc|
        css_id = "CSSID#{generate :css_id}"

        intake_user = User.find_by(css_id: css_id)

        if intake_user.nil?
          intake_user = create(:user, css_id: css_id)
        end

        create(:intake, :completed, detail: sc, veteran_file_number: sc.veteran_file_number, user: intake_user)
      end
    end

    trait :with_decision do
      after(:create) do |sc|
        create(
          :decision_issue,
          decision_review: sc,
          request_issues: sc.request_issues,
          benefit_type: sc.benefit_type,
          disposition: "Granted",
          caseflow_decision_date: 5.days.ago.to_date
        )
      end
    end

    trait :unidentified_issue do
      after(:create) do |sc, evaluator|
        create(:request_issue,
               :unidentified,
               :add_decision_date,
               benefit_type: sc.benefit_type,
               decision_review: sc,
               decision_date: evaluator.decision_date.presence ? evaluator.decision_date : nil)
      end
    end

    trait :with_update_users do
      after(:create) do |sc|
        sc.create_business_line_tasks!

        create(:request_issues_update, :requires_processing, review: sc)
      end
    end

    trait :update_assigned_at do
      after(:create) do |sc, evaluator|
        sc.create_business_line_tasks!
        task = sc.tasks.last
        task.assigned_at = evaluator.assigned_at
        task.save!
      end
    end

    trait :without_decision_date do
      after(:create) do |sc, evaluator|
        create(:request_issue,
               benefit_type: sc.benefit_type,
               nonrating_issue_category: evaluator.issue_type,
               nonrating_issue_description: "#{sc.business_line.name} #{evaluator.description}",
               decision_review: sc)
      end
    end
  end
end
