# frozen_string_literal: true

FactoryBot.define do
  factory :judge_case_review do
    location { JudgeCaseReview.location.keys.sample }
    task_id { "123456-2017-08-07" }
    complexity { "medium" }
    quality { "outstanding" }
    judge { create(:user) }
    attorney { create(:user) }
    appeal { nil }

    after(:create) do |case_review, _evaluator|
      case_review.appeal # creates association to appeal if it doesn't exist
    end

    trait :ama do
      location { :quality_review }
      task factory: :ama_task
    end

    trait :legacy do
      location { :quality_review }
      appeal { create(:legacy_appeal, vacols_case: create(:case)) }
    end
  end
end
