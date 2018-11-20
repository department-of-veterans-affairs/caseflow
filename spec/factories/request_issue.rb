FactoryBot.define do
  factory :request_issue do
    review_request_type "Appeal"
    sequence(:review_request_id) { |n| "review#{n}" }

    factory :request_issue_with_epe do
      end_product_establishment { create(:end_product_establishment) }
    end

    transient do
      decision_issues []
    end

    after(:create) do |request_issue, evaluator|
      if evaluator.decision_issues.present?
        request_issue.decision_issues << evaluator.decision_issues
        request_issue.save
      end
    end
  end
end
