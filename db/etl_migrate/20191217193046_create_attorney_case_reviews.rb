class CreateAttorneyCaseReviews < ActiveRecord::Migration[5.1]
  def change
    create_table :attorney_case_reviews, comment: "Denormalized attorney_case_reviews" do |t|
      t.bigint "review_id", null: false, comment: "attorney_case_reviews.id"
      t.string "task_id", null: false, comment: "attorney_case_reviews.task_id"
      t.string "vacols_id", comment: "Substring attorney_case_reviews.task_id for Legacy Appeals"
      t.bigint "appeal_id", null: false, comment: "tasks.appeal_id"
      t.string "appeal_type", null: false, comment: "tasks.appeal_type"
      t.bigint "reviewing_judge_id", null: false, comment: "attorney_case_reviews.reviewing_judge_id"
      t.string "reviewing_judge_css_id", null: false, limit: 20, comment: "users.css_id"
      t.string "reviewing_judge_full_name", null: false, limit: 255, comment: "users.full_name"
      t.string "reviewing_judge_sattyid", limit: 20, comment: "users.sattyid"
      t.bigint "attorney_id", null: false, comment: "attorney_case_reviews.attorney_id"
      t.string "attorney_css_id", null: false, limit: 20, comment: "users.css_id"
      t.string "attorney_full_name", null: false, limit: 255, comment: "users.full_name"
      t.string "attorney_sattyid", limit: 20, comment: "users.sattyid"
      t.string "work_product", limit: 20, comment: "attorney_case_reviews.work_product"
      t.string "document_reference_id", limit: 50, comment: "attorney_case_reviews.document_id"
      t.string "document_type", limit: 20, comment: "attorney_case_reviews.document_type"
      t.boolean "overtime", comment: "attorney_case_reviews.overtime"
      t.boolean "untimely_evidence", comment: "attorney_case_reviews.untimely_evidence"
      t.text "note", comment: "attorney_case_reviews.note"
      t.datetime "review_created_at", null: false, comment: "attorney_case_reviews.created_at"
      t.datetime "review_updated_at", null: false, comment: "attorney_case_reviews.updated_at"
      t.datetime "created_at", null: false, comment: "Default created_at/updated_at for the ETL record"
      t.datetime "updated_at", null: false, comment: "Default created_at/updated_at for the ETL record"

      t.index ["review_id"]
      t.index ["created_at"]
      t.index ["review_created_at"]
      t.index ["updated_at"]
      t.index ["review_updated_at"]
      t.index ["vacols_id"]
      t.index ["task_id"]
      t.index ["appeal_id"]
      t.index ["appeal_type"]
      t.index ["reviewing_judge_id"]
      t.index ["attorney_id"]
      t.index ["document_type"]
    end
  end
end
