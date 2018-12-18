FactoryBot.define do
  factory :attorney_case_review do
    task_id { "123456-2017-08-07" }
    document_id "173250939.1116"
    overtime false
    work_product "Decision"
    document_type "draft_decision"
    reviewing_judge { create(:user) }
    attorney { create(:user) }
  end
end
