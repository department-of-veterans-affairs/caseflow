# frozen_string_literal: true

FactoryBot.define do
  factory :request_decision_issue do
    association :request_issue
    association :decision_issue
  end
end
