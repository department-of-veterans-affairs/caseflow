class RenameBackfillRecordToEventedRecord < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      rename_column :event_records, :backfill_record_id, :evented_record_id
      rename_column :event_records, :backfill_record_type, :evented_record_type
      rename_index :event_records, "index_event_record_on_backfill_record", "index_event_record_on_evented_record"
    end
  end
end
