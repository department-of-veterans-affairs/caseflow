class AddEventIdToMetrics < ActiveRecord::Migration[5.2]
  def change
    add_column :metrics, :event_id, :uuid
  end
end
