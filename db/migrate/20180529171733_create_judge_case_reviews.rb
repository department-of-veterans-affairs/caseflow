class CreateJudgeCaseReviews < ActiveRecord::Migration[5.1]
  def change
    create_table :judge_case_reviews do |t|
      t.integer "attorney_id"
      t.integer "judge_id"
      t.string "task_id"
      t.string  "complexity"
      t.string "quality"
      t.string "location"
      t.text "comment"
      t.text "factors_not_considered", array: true, default: []
      t.text "areas_for_improvement", array: true, default: []
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
