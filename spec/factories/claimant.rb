# frozen_string_literal: true

FactoryBot.define do
  factory :claimant do
    sequence(:decision_review_id)
    sequence(:participant_id)
    association :decision_review, factory: :appeal

    trait :advanced_on_docket_due_to_age do
      after(:create) do |claimant, _evaluator|
        claimant.person.update!(date_of_birth: 76.years.ago)
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
