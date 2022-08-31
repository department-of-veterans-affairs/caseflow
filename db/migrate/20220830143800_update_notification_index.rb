class UpdateNotificationIndex < Caseflow::Migration
  def up
    delete_duplicated_records
    remove_index :notifications, name: "index_appeals_notifications_on_appeals_id_and_appeals_type"
    add_safe_index :notifications, [:appeals_id, :appeals_type], name: "index_appeals_notifications_on_appeals_id_and_appeals_type", unique: true
  end

  def down
    remove_index :notifications, name: "index_appeals_notifications_on_appeals_id_and_appeals_type"
    add_safe_index :notifications, [:appeals_id, :appeals_type], name: "index_appeals_notifications_on_appeals_id_and_appeals_type", unique: false
  end

  private

  def delete_duplicated_records
    dup_notification_ids = Notification.group(:appeals_id, :appeals_type).having('COUNT(*) > 1').pluck(:appeals_id)
    dup_notification_ids.each_slice(400) do |dupe_ids|
      not_remove_order_ids = Notification.where(appeals_id: dupe_ids).group(:appeals_id, :appeals_type).having('COUNT(*) > 1').pluck('MIN(id)')
      Notification.where(appeals_id: dupe_ids).where.not(id: not_remove_order_ids).destroy_all
    end
  end
end