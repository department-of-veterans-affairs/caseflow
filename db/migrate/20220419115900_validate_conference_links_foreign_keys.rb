class ValidateConferenceLinksForeignKeys < ActiveRecord::Migration[5.2]
  def change
    validate_foreign_key "conference_links", column: "created_by_id"
    validate_foreign_key "conference_links", column: "updated_by_id"
    validate_foreign_key "conference_links", column: "hearing_day_id"
  end
end