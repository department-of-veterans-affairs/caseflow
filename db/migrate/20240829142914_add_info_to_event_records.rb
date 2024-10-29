class AddInfoToEventRecords < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    add_column :event_records, :info, :jsonb, default: {}
    add_index :event_records, :info, using: :gin, algorithm: :concurrently
  end

  def down
    remove_index :event_records, column: :info, algorithm: :concurrently
    remove_column :event_records, :info
  end
end
