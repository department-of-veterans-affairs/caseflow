FactoryBot.define do
  factory :request_issue do
    review_request_type "Appeal"
    sequence(:review_request_id) { |n| "review#{n}" }

    factory :request_issue_with_epe do
      end_product_establishment { create(:end_product_establishment) }
    end
  end
end
