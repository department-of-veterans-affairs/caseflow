class AddIndexesToNotifications < ActiveRecord::Migration[5.2]
  def change
    add_safe_index :notifications, [:participant_id], name: "index_participant_id"
    add_safe_index :notifications, [:appeals_id], name: "index_appeals_id"
    add_safe_index :notifications, [:appeals_type], name: "index_appeals_type"
  end
end
