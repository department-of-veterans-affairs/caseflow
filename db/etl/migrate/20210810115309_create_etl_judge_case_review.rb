# frozen_string_literal: true

class CreateEtlJudgeCaseReview < Caseflow::Migration
  def change
    create_table :judge_case_reviews do |t|
      t.timestamps null: false, comment: "Default created_at/updated_at for the ETL record"
      t.index ["created_at"]
      t.index ["updated_at"]

      t.datetime "review_created_at", null: false, comment: "judge_case_reviews.created_at"
      t.datetime "review_updated_at", null: false, comment: "judge_case_reviews.updated_at"
      t.index ["review_created_at"]
      t.index ["review_updated_at"]

      t.bigint "review_id", null: false, comment: "judge_case_reviews.id"
      t.index ["review_id"]

      t.integer "judge_id", comment: "judge_case_reviews.judge_id; references users table"
      t.index ["judge_id"]
      t.bigint "attorney_id", null: false, comment: "judge_case_reviews.attorney_id; references users table"
      t.index ["attorney_id"]

      t.string "judge_css_id", null: false, limit: 20, comment: "users.css_id"
      t.string "judge_full_name", null: false, limit: 255, comment: "users.full_name"
      t.string "judge_sattyid", limit: 20, comment: "users.sattyid"
      t.string "attorney_css_id", null: false, limit: 20, comment: "users.css_id"
      t.string "attorney_full_name", null: false, limit: 255, comment: "users.full_name"
      t.string "attorney_sattyid", limit: 20, comment: "users.sattyid"

      t.text "areas_for_improvement", default: [], array: true
      t.text "comment", comment: "from judge"
      t.string "complexity"
      t.text "factors_not_considered", default: [], array: true
      t.string "location"
      t.boolean "one_touch_initiative"
      t.text "positive_feedback", default: [], array: true
      t.string "quality"

      t.string "original_task_id", comment: "judge_case_reviews.task_id; Refers to the tasks table for AMA appeals, but uses syntax `<vacols_id>-YYYY-MM-DD` for legacy appeals"
      t.index ["original_task_id"]
      t.string "actual_task_id", comment: "Substring from judge_case_reviews.task_id referring to the tasks table for AMA Appeals"
      t.index ["actual_task_id"]
      t.string "vacols_id", comment: "Substring from judge_case_reviews.task_id for Legacy Appeals"
      t.index ["vacols_id"]

      t.bigint "appeal_id", null: false, comment: "tasks.appeal_id"
      t.index ["appeal_id"]
      t.string "appeal_type", null: false, comment: "tasks.appeal_type"
      t.index ["appeal_type"]
    end

    # Do not add foreign keys because they rely on the order in which the *Syncers run
    # and because associated records cannot be easily deleted by ETL::Sweeper.
    # add_foreign_key :judge_case_reviews, "users", column: "judge_id", validate: false
    # add_foreign_key :judge_case_reviews, "users", column: "attorney_id", validate: false
  end
end
