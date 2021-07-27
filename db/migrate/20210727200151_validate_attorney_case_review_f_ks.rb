class ValidateAttorneyCaseReviewFKs < Caseflow::Migration
  def change
    validate_foreign_key "judge_case_reviews", "attorney_id"
    validate_foreign_key "judge_case_reviews", "judge_id"
  end
end
