FactoryBot.define do
  factory :judge_case_review do
    location { JudgeCaseReview.location.keys.sample }
    task_id { "123456-2017-08-07" }
    complexity "medium"
    quality "outstanding"
    judge { create(:user) }
    attorney { create(:user) }
  end
end
