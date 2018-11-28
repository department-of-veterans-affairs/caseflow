FactoryBot.define do
  factory :decision_issue do
    sequence(:participant_id, 500_000_000)
    disposition "allowed"
    disposition_date 3.days.ago

    transient do
      request_issues []
    end
    after(:create) do |decision_issue, evaluator|
      if evaluator.request_issues
        decision_issue.request_issues << evaluator.request_issues
        decision_issue.save
      end
    end
  end
end
