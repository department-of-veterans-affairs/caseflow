class CreateEventRecords < Caseflow::Migration
  def change
    create_table :event_records, comment: "Stores records that are created or updated by an event from the Appeals-Consumer application." do |t|
      t.integer :event_id, null: false, foreign_key: { to_table: :events }, comment: "ID of the Event that created or updated this record."
      t.timestamp :created_at, null: false, comment: "Automatic timestamp when row was created"
      t.timestamp :updated_at, null: false, comment: "Automatic timestamp whenever the record changes"

      t.references :backfill_record, null: false, polymorphic: true, index: {:name => "index_event_record_on_backfill_record"}
    end
  end
end
