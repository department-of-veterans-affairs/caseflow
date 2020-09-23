# frozen_string_literal: true

class CreateDocketChanges < ActiveRecord::Migration[5.2]
  def change
    create_table :docket_changes, comment: "Stores the disposition and associated data for Docket Change motions" do |t|
      t.belongs_to :appeal, null: false, foreign_key: true
      t.belongs_to :task, null: false, foreign_key: true
      t.datetime "receipt_date", null: false
      t.string "docket", comment: "The new docket"
      t.string "disposition", comment: "Possible options are granted, partially_granted, and denied"
      t.integer "granted_decision_issue_ids", comment: "When a docket change is partially granted, this includes an array of the appeal's decision issue IDs that were selected for the new docket. For full grant, this includes all prior decision issue IDs.", array: true
      t.timestamps null: false, comment: "Standard created_at/updated_at timestamps"

      t.index ["created_at"]
    end
  end
end
