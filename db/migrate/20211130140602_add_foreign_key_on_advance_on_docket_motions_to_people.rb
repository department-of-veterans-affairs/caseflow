class AddForeignKeyOnAdvanceOnDocketMotionsToPeople < Caseflow::Migration
  def change
    add_foreign_key "advance_on_docket_motions", "people", column: "person_id", validate: false
  end
end
