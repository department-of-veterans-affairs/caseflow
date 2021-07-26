class ValidateAttorneyCaseReviewFKs < Caseflow::Migration
  def change
    validate_foreign_key "attorney_case_reviews", column: "attorney_id"
    validate_foreign_key "attorney_case_reviews", column: "reviewing_judge_id"
    validate_foreign_key "attorney_case_reviews", "tasks"
  end
end
