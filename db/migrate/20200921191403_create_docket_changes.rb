# frozen_string_literal: true

class CreateDocketChanges < ActiveRecord::Migration[5.2]
  def change
    create_table :docket_changes, comment: "Stores the disposition and associated data for Docket Change motions" do |t|
      t.references :old_docket_stream, references: :appeals, null: false, foreign_key: { to_table: :appeals }, comment: "References the original appeal stream with old docket"
      t.references :new_docket_stream, references: :appeals, null: true, foreign_key: { to_table: :appeals }, comment: "References the new appeal stream with the updated docket; initially null until created by workflow"
      t.belongs_to :task, null: false, foreign_key: true, comment: "The task that triggered the switch"
      t.datetime "receipt_date", null: false
      t.string "docket_type", comment: "The new docket"
      t.string "disposition", comment: "Possible options are granted, partially_granted, and denied"
      t.integer "granted_request_issue_ids", comment: "When a docket change is partially granted, this includes an array of the appeal's request issue IDs that were selected for the new docket. For full grant, this includes all prior request issue IDs.", array: true
      t.timestamps null: false, comment: "Standard created_at/updated_at timestamps"

      t.index ["created_at"]
    end
  end
end
