# frozen_string_literal: true

FactoryBot.define do
  factory :request_issues_update do
    user { create(:user) }
    review { create(:higher_level_review) }
    before_request_issue_ids { [create(:request_issue_with_epe).id] }
    after_request_issue_ids { [create(:request_issue_with_epe).id] }
    withdrawn_request_issue_ids { [] }
    edited_request_issue_ids { [] }

    trait :requires_processing do
      submitted_at { (RequestIssuesUpdate.processing_retry_interval_hours + 1).hours.ago }
      last_submitted_at { (RequestIssuesUpdate.processing_retry_interval_hours + 1).hours.ago }
      processed_at { nil }
    end
  end
end
