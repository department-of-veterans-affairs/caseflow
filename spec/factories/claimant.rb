FactoryBot.define do
  factory :claimant do
    sequence(:review_request_id)
    sequence(:participant_id)
    review_request_type "appeal"
  end
end
