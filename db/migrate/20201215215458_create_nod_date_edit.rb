class CreateNodDateEdit < ActiveRecord::Migration[5.2]
  def change
    create_table :nod_date_edits do |t|
      t.bigint "appeal_id", null: false, comment: "Appeal that NOD date is being edited for"
      t.date "old_value", null: false, comment: "Value before update"
      t.date "new_value", null: false, comment: "Value after update"
      t.bigint "created_by_id", null: false, comment: "User that created this record"
      t.string "change_reason", null: false, comment: "Reason for change"

      t.timestamps null: false, comment: "Default created_at/updated_at timestamps"
    end

    add_index :nod_date_edits, :appeal_id, algorithm: :concurrently
  end
end
