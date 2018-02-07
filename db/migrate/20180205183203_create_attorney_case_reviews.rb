class CreateAttorneyCaseReviews < ActiveRecord::Migration
  def change
    create_table :attorney_case_reviews do |t|
      t.string  "document_id"
      t.integer "reviewing_judge_id"
      t.integer "attorney_id"
      t.string  "work_product"
      t.boolean  "overtime", default: false
      t.string "type"
      t.text "note"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
