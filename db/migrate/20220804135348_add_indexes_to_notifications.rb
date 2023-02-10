class AddIndexesToNotifications < Caseflow::Migration
  def change
    add_safe_index :notifications, [:participant_id], name: "index_participant_id"
    add_safe_index :notifications, [:appeals_id, :appeals_type], name: "index_appeals_notifications_on_appeals_id_and_appeals_type"
  end
end
