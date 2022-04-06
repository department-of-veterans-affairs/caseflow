class ValidateForeignKeyOnConferenceLink < Caseflow::Migration
    def change
        validate_foreign_key "conference_link", column: "created_by_id"
        validate_foreign_key "conference_link", column: "hearing_day_id"
    end
  end