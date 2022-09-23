# frozen_string_literal: true

FactoryBot.define do
  factory :attorney_case_review do
    task_id { "123456-2017-08-07" }
    document_id { "17325093.1116" }
    overtime { false }
    untimely_evidence { false }
    work_product { "Decision" }
    document_type { "draft_decision" }
    reviewing_judge do
      User.find_by_css_id("ID_FACT_ACR_J") ||
        create(:user, css_id: "ID_FACT_ACR_J", full_name: "Jane AttorneyCaseReviewFactory Judge")
    end
    attorney do
      User.find_by_css_id("ID_FACT_ACR_A") ||
        create(:user, css_id: "ID_FACT_ACR_A", full_name: "Joe AttorneyCaseReviewFactory Atty")
    end
    appeal { nil }

    after(:create) do |case_review, _evaluator|
      case_review.appeal # creates association to appeal if it doesn't exist
    end
  end
end
