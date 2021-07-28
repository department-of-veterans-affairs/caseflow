class AddAttorneyCaseReviewFKs < Caseflow::Migration
  def change
    add_foreign_key "attorney_case_reviews", "users", column: "attorney_id", validate: false
    add_foreign_key "attorney_case_reviews", "users", column: "reviewing_judge_id", validate: false
    change_column_comment :attorney_case_reviews, :task_id, "Refers to the tasks table for AMA appeals, but something like `4107503-2021-05-31` for legacy appeals"
    change_column_comment :judge_case_reviews, :task_id, "Refers to the tasks table for AMA appeals, but something like `4107503-2021-05-31` for legacy appeals"
  end
end
