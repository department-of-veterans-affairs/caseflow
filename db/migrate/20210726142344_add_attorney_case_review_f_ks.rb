class AddAttorneyCaseReviewFKs < Caseflow::Migration
  def change
    add_foreign_key "attorney_case_reviews", "users", column: "attorney_id", validate: false
    add_foreign_key "attorney_case_reviews", "users", column: "reviewing_judge_id", validate: false
  end
end