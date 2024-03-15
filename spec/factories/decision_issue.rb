# frozen_string_literal: true

FactoryBot.define do
  factory :decision_issue do
    participant_id { generate :participant_id }
    disposition { "allowed" }
    benefit_type { "compensation" }
    diagnostic_code { "9999" }
    end_product_last_action_date { decision_review.is_a?(Appeal) ? nil : 5.days.ago.to_date }
    caseflow_decision_date { decision_review.is_a?(Appeal) ? 5.days.ago.to_date : nil }
    decision_review { create(:higher_level_review) }

    description { decision_review.is_a?(Appeal) ? "description #{Faker::Lorem.words(number: 4).join(' ')}" : nil }

    transient do
      request_issues { [] }
    end

    transient do
      remand_reasons { [] }
    end

    trait :ama do
      decision_review factory: :appeal
    end

    trait :higher_level_review do
      decision_review { create(:higher_level_review, number_of_claimants: 0) }
    end

    trait :supplemental_claim do
      decision_review { create(:supplemental_claim, number_of_claimants: 0) }
    end

    trait :nonrating do
      request_issues { [create(:request_issue, :nonrating, decision_review: decision_review)] }
    end

    trait :rating do
      request_issues { [create(:request_issue, :rating, decision_review: decision_review)] }
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
