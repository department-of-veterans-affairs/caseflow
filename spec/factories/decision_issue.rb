FactoryBot.define do
  factory :decision_issue do
    association :source_request_issue, factory: :request_issue
    disposition "allowed"
    disposition_date 3.days.ago
  end
end
