FactoryBot.define do
  factory :decision_issue do
    request_issue
    disposition "allowed"
    disposition_date 3.days.ago
  end
end
