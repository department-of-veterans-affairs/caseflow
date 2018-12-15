FactoryBot.define do
  factory :legacy_issue_optin do
    request_issue { create(:request_issue) }
    vacols_id { request_issue.vacols_id }
    vacols_sequence_id { request_issue.vacols_sequence_id }
  end
end
