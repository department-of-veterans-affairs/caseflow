# frozen_string_literal: true

class CreateDocketChanges < ActiveRecord::Migration[5.2]
  def change
    create_table :docket_changes, comment: "Stores the disposition and associated data for Docket Change motions", force: :cascade do |t|
      t.bigint "appeal_id"
      t.datetime "created_at", null: false
      t.datetime "receipt_date", null: false
      t.string "docket", comment: "The new docket"
      t.string "disposition", comment: "Possible options are Grant, Partial Grant, and Deny"
      t.bigint "task_id", comment: "Refers to the task use during checkout flow"
      t.datetime "updated_at", null: false
      t.integer "granted_decision_issue_ids", comment: "When a docket change is partially granted, this includes an array of the appeal's decision issue IDs that were selected for the new docket. For full grant, this includes all prior decision issue IDs.", array: true

      t.index ["appeal_id"], name: "index_docket_changes_on_appeal_id"
      t.index ["task_id"], name: "index_docket_changes_on_task_id"
      t.index ["updated_at"], name: "index_docket_changes_on_updated_at"
    end
  end
end
