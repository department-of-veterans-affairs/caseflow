# frozen_string_literal: true

FactoryBot.define do
  factory :legacy_issue_optin do
    request_issue { create(:request_issue) }
    original_disposition_code { request_issue.vacols_issue.disposition_id }
    original_disposition_date { request_issue.vacols_issue.disposition_date }
  end
end
