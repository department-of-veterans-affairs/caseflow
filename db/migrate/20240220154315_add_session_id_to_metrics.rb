class AddSessionIdToMetrics < ActiveRecord::Migration[5.2]
  def change
    add_column :metrics, :session_id, :uuid
  end
end
