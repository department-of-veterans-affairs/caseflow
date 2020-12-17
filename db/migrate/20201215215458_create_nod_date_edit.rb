class CreateNodDateEdit < Caseflow::Migration
  def change
    create_table :nod_date_edits do |t|
      t.references "appeal", null: false, foreign_key: true, comment: "Appeal that NOD date is being edited for"
      t.date "old_value", null: false, comment: "Value before update"
      t.date "new_value", null: false, comment: "Value after update"
      t.references "user", null: false, foreign_key: true, comment: "User that created this record"
      t.string "change_reason", null: false, comment: "Reason for change - entry_error or new_info"

      t.timestamps null: false, comment: "Default created_at/updated_at timestamps"
    end
  end
end
