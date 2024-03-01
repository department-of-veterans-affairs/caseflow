# frozen_string_literal: true

FactoryBot.define do
  factory :claimant do
    sequence(:decision_review_id)
    participant_id { generate :participant_id }
    association :decision_review, factory: :appeal

    initialize_with do
      klass = attributes[:type]&.constantize
      decision_review = attributes[:decision_review]
      if decision_review
        klass ||= (decision_review.veteran_is_not_claimant ? DependentClaimant : VeteranClaimant)
      end
      klass ||= VeteranClaimant
      if klass == VeteranClaimant
        attributes[:participant_id] ||= decision_review&.veteran&.participant_id
      end
      klass.new(**attributes)
    end

    trait :ama do
      decision_review { create(:appeal, number_of_claimants: 0) }
    end

    trait :legacy do
      decision_review { create(:legacy_appeal, vacols_case: create(:case)) }
    end

    trait :higher_level_review do
      decision_review { create(:higher_level_review, number_of_claimants: 0, benefit_type: "vha") }
    end

    trait :supplemental_claim do
      decision_review { create(:supplemental_claim, number_of_claimants: 0, benefit_type: "vha") }
    end

    trait :advanced_on_docket_due_to_age do
      after(:create) do |claimant, _evaluator|
        claimant.person.update!(date_of_birth: 76.years.ago)
      end
    end

    trait :with_unrecognized_appellant_detail do
      after(:create) do |claimant, _evaluator|
        create(:unrecognized_appellant, claimant: claimant)
      end
    end

    trait :attorney do
      initialize_with { AttorneyClaimant.new(attributes) }
      type { AttorneyClaimant.name }
      after(:create) do |claimant, _evaluator|
        claimant.person
        name = claimant.person&.name || "Seeded AttyClaimant"
        create(:bgs_attorney, name: name, participant_id: claimant.participant_id)
      end
    end

    after(:create) do |claimant, _evaluator|
      # ensure that an associated person record is created in our DB
      # & date_of_birth is populated
      claimant.person&.date_of_birth

      if claimant.decision_review&.veteran&.participant_id == claimant.participant_id
        veteran = claimant.decision_review.veteran
        claimant.person.update!(first_name: veteran.first_name, last_name: veteran.last_name)
      end
    end
  end
end
