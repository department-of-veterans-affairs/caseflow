# frozen_string_literal: true

FactoryBot.define do
  factory :attorney_case_review do
    task_id { "123456-2017-08-07" }
    document_id { "17325093.1116" }
    overtime { false }
    untimely_evidence { false }
    work_product { "Decision" }
    document_type { "draft_decision" }
    reviewing_judge { create(:user) }
    attorney { create(:user) }
  end
end
