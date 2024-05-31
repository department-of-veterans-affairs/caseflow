class AddInfoToEvents < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    add_column :events, :info, :jsonb, default: {}
    safety_assured { execute(<<-SQL) }
      CREATE INDEX CONCURRENTLY index_events_on_info
      ON events USING gin (info);
    SQL
  end

  def down
    remove_column :events, :info
  end
end
