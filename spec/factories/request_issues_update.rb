FactoryBot.define do
  factory :request_issues_update do
    user { create(:user) }
    review { create(:higher_level_review) }
    before_request_issue_ids { [create(:request_issue).id] }
    after_request_issue_ids { [create(:request_issue).id] }
  end
end
