FactoryBot.define do
  factory :decision_issue do
    sequence(:participant_id, 500_000_000)
    disposition "allowed"

    transient do
      request_issues []
    end
    transient do
      remand_reasons []
    end

    after(:create) do |decision_issue, evaluator|
      if evaluator.request_issues
        decision_issue.request_issues << evaluator.request_issues
        decision_issue.save
      end

      if evaluator.remand_reasons
        decision_issue.remand_reasons << evaluator.remand_reasons
        decision_issue.disposition = "remanded"
        decision_issue.save
      end
    end
  end
end
