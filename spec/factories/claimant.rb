FactoryBot.define do
  factory :claimant do
    sequence(:review_request_id)
    sequence(:participant_id)
    review_request_type "Appeal"
    # person do
    #   create(:person)
    # end

    trait :advanced_on_docket_due_to_age do
      after(:create) do |claimant, _evaluator|
        claimant.person.update!(date_of_birth: 76.years.ago)
      end
    end
  end
end
