class ValidateForeignKeysOnEvents < ActiveRecord::Migration[5.2]
  def change
    validate_foreign_key "event_records", name: "event_records_event_id_fk"
  end
end
