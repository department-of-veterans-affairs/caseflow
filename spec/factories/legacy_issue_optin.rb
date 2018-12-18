FactoryBot.define do
  factory :legacy_issue_optin do
    request_issue { create(:request_issue) }
  end
end
