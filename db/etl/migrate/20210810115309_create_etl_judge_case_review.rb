class CreateEtlJudgeCaseReview < Caseflow::Migration
  def change
    create_table :judge_case_reviews do |t|
      t.text "areas_for_improvement", default: [], array: true
      t.integer "attorney_id"
      t.text "comment"
      t.string "complexity"
      t.datetime "created_at", null: false
      t.text "factors_not_considered", default: [], array: true
      t.integer "judge_id"
      t.string "location"
      t.boolean "one_touch_initiative"
      t.text "positive_feedback", default: [], array: true
      t.string "quality"
      t.string "task_id", comment: "Refers to the tasks table for AMA appeals, but uses syntax `<vacols_id>-YYYY-MM-DD` for legacy appeals"
      t.datetime "updated_at", null: false
      t.index ["updated_at"], name: "index_judge_case_reviews_on_updated_at"
    end
  end
end
