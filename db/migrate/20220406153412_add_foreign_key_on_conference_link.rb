class AddForeignKeyOnConferenceLink < Caseflow::Migration
    def change
      add_foreign_key "conference_link", "users", validate: false
      add_foreign_key "conference_link", "hearing_day", validate: false
    end
  end