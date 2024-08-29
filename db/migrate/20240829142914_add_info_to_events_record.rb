class AddInfoToEventsRecord < ActiveRecord::Migration[6.0]
  def change
    add_column :event_records, :info, :jsonb
  end
end
