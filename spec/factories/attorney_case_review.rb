FactoryBot.define do
  factory :attorney_case_review do
    overtime false
    attorney { create(:user) }
    document_type :draft_decision
    reviewing_judge { create(:user) }
    sequence(:document_id)
    work_product "Decision"
  end
end
