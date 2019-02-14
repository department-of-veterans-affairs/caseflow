FactoryBot.define do
  factory :decision_issue do
    sequence(:participant_id, 500_000_000)
    disposition "allowed"
    benefit_type "compensation"
    diagnostic_code "9999"
    end_product_last_action_date { decision_review.is_a?(Appeal) ? nil : 5.days.ago.to_date }
    caseflow_decision_date { decision_review.is_a?(Appeal) ? 5.days.ago.to_date : nil }
    decision_review { create(:higher_level_review) }

    description { decision_review.is_a?(Appeal) ? "description" : nil }

    transient do
      request_issues []
    end

    transient do
      remand_reasons []
    end

    trait :nonrating do
      request_issues { [create(:request_issue, :nonrating, review_request: decision_review)] }
    end

    trait :rating do
      request_issues { [create(:request_issue, :rating, review_request: decision_review)] }
    end

    trait :imo do
      remand_reasons { [create(:ama_remand_reason, code: "advisory_medical_opinion")] }
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
