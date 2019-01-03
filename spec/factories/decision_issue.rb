FactoryBot.define do
  factory :decision_issue do
    sequence(:participant_id, 500_000_000)
    disposition "allowed"
    benefit_type "compensation"
    description "description"

    transient do
      request_issues []
    end

    transient do
      remand_reasons []
    end

    trait :nonrating do
      request_issues { [create(:request_issue, :nonrating)] }
    end

    trait :rating do
      request_issues { [create(:request_issue, :rating)] }
    end

    after(:create) do |decision_issue, evaluator|
      if evaluator.request_issues
        decision_issue.request_issues << evaluator.request_issues
        decision_issue.save
      end

      if evaluator.remand_reasons.any?
        decision_issue.remand_reasons << evaluator.remand_reasons
        decision_issue.disposition = "remanded"
        decision_issue.save
      end
    end
  end
end
