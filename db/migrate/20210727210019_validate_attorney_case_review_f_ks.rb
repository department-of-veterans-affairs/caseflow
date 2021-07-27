class ValidateAttorneyCaseReviewFKs < Caseflow::Migration
  def change
    validate_foreign_key "attorney_case_reviews", "attorney_id"
    validate_foreign_key "attorney_case_reviews", "reviewing_judge_id"
  end
end