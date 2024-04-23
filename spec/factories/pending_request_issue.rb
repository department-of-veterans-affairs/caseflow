# frozen_string_literal: true

FactoryBot.define do
  factory :pending_request_issue do
    request_type { "Addition" }
    request_date { 1.month.ago }
    request_reason { "lorem ipsum" }
    benefit_type { "vha" }
    approved_status { false }
    nonrating_issue_category { "Dental"}
  end
end
