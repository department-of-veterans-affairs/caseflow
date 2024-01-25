class AddForeignKeyToEvents < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key "event_records", "events", name: "event_records_event_id_fk", validate: false
  end
end
