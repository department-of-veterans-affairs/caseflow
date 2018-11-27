FactoryBot.define do
  factory :legacy_issue_optin do
    review_request { create(:appeal) }
    request_issue { create(:request_issue) }
  end
end
