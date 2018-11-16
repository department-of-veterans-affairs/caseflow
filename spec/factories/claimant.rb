FactoryBot.define do
  factory :claimant do
    sequence(:review_request_id)
    sequence(:participant_id)
    review_request_type "Appeal"

    trait :advanced_on_docket do
      after(:create) do |claimant, _evaluator|
        create(:person, date_of_birth: 76.years.ago, participant_id: claimant.participant_id)
      end
    end
  end
end
