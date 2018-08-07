FactoryBot.define do
  factory :decision_issue do
    request_issue
    disposition { Constants::ISSUE_DISPOSITIONS.keys.sample }
    disposition_date { 3.days.ago }
  end
end