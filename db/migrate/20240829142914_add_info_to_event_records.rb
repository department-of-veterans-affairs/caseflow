class AddInfoToEventRecords < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    add_column :event_records, :info, :jsonb, default: {}
    safety_assured { execute(<<-SQL) }
      CREATE INDEX CONCURRENTLY index_event_records_on_info
      ON event_records USING gin (info);
    SQL
  end

  def down
    safety_assured { remove_column :event_records, :info }
  end
end
