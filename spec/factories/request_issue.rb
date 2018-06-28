FactoryBot.define do
  factory :request_issue do
    review_request_type "Appeal"
    sequence(:review_request_id) { |n| "review#{n}" }
  end
end
