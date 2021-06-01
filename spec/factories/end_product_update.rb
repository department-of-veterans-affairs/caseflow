# frozen_string_literal: true

FactoryBot.define do
  factory :end_product_update do
    user { create(:user) }
    original_decision_review { create(:higher_level_review) }

    transient do
      number_of_request_issues { 2 }
    end

    after(:build) do |epu, evaluator|
      issue_type = Constants.EP_CLAIM_TYPES.to_h[epu.original_code.to_sym][:issue_type].to_sym
      create_list(
        :request_issue,
        evaluator.number_of_request_issues,
        issue_type,
        decision_review: epu.end_product_establishment.source,
        end_product_establishment: epu.end_product_establishment
      )
    end
  end
end
