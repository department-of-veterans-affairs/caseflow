class AddEventIdToMetrics < ActiveRecord::Migration[5.2]
  def change
    add_column :metrics, :event_id, :uuid, comment: "Track metrics for retrieving loading and viewing a single pdf document."
  end
end
