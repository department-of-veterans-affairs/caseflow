class AddForeignKeyOnConferenceLink < Caseflow::Migration
    def change
      add_foreign_key "conference_link", "users", column: "created_by_id", validate: false
      add_foreign_key "conference_link", "hearing_days", column: "hearing_day_id", validate: false
    end
  end