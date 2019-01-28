FactoryBot.define do
  factory :claimant do
    sequence(:review_request_id)
    sequence(:participant_id)
    review_request_type "Appeal"

    trait :advanced_on_docket_due_to_age do
      after(:create) do |claimant, _evaluator|
        claimant.person.update!(date_of_birth: 76.years.ago)
      end
    end

    after(:create) do |claimant, _evaluator|
      # ensure that an associated person record is created in our DB
      # & date_of_birth is populated
      claimant.person&.date_of_birth
    end
  end
end
