class CreateNodDateUpdate < Caseflow::Migration
  def change
    create_table :nod_date_updates, comment: "Tracks changes to an AMA appeal's receipt date (aka, NOD date)" do |t|
      t.references "appeal", null: false, foreign_key: true, comment: "Appeal for which the NOD date is being edited"
      t.date "old_date", null: false, comment: "Date before update"
      t.date "new_date", null: false, comment: "Date after update"
      t.references "user", null: false, foreign_key: true, comment: "User that updated the NOD date"
      t.string "change_reason", null: false, comment: "Reason for change: entry_error or new_info"

      t.timestamps null: false, comment: "Default created_at/updated_at timestamps"
    end
  end
end
