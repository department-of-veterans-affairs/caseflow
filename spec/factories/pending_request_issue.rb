# frozen_string_literal: true

FactoryBot.define do
  factory :pending_request_issue do
    request_type { "Addition" }
    request_date { 1.month.ago }
    request_reason { "lorem ipsum" }

    benefit_type { "vha" }
    nonrating_issue_category { "Dental"}
    status { PendingRequestIssue.statuses.keys.sample }

    association(:decision_review, factory: [:appeal, :with_post_intake_tasks])
    association(:request_issue)
    decision_date { nil }
    decision_text { nil }
    withdrawal_date { nil }
    remove_original_issue { false }

    trait :pending_status do
      status { :pending }
    end

    trait :accepted_status do
      status { :accepted }
    end

    trait :rejected_status do
      status { :rejected }
    end

    trait :canceled_status do
      status { :canceled }
    end
  end
end
