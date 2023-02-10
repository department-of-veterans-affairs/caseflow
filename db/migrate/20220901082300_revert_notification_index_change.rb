# Public: Active migration to handle the Migration and Rollback of making the
# index_appeals_notifications_on_appeals_id_and_appeals_type index unique
class RevertNotificationIndexChange < Caseflow::Migration

  # Purpose: Method to re create the index_appeals_notifications_on_appeals_id_and_appeals_type index to be not 
  # unique in case of rollback from this migration
  #
  # Params: None
  #
  # Returns: None
  def up
    remove_index :notifications, name: "index_appeals_notifications_on_appeals_id_and_appeals_type"
    add_safe_index :notifications, [:appeals_id, :appeals_type], name: "index_appeals_notifications_on_appeals_id_and_appeals_type", unique: false
  end

  # Purpose: Code and logic needed to re create the index_appeals_notifications_on_appeals_id_and_appeals_type index
  # to now require the combination the columns [:appeals_id, :appeals_type] to be unique.
  # Given the index use to not be unique this method also calls delete_duplicated_records to clean up the code
  # before the new index can be applied
  #
  # Params: None
  #
  # Returns: None
  def down
    delete_duplicated_records
    remove_index :notifications, name: "index_appeals_notifications_on_appeals_id_and_appeals_type"
    add_safe_index :notifications, [:appeals_id, :appeals_type], name: "index_appeals_notifications_on_appeals_id_and_appeals_type", unique: true
  end

  private
  # Purpose: Removing duplicate records that were allwoed by the index when it was not unique
  #
  # Params: None
  #
  # Returns: None
  def delete_duplicated_records
    dup_notification_ids = Notification.group(:appeals_id, :appeals_type).having('COUNT(*) > 1').pluck(:appeals_id)
    dup_notification_ids.each_slice(400) do |dupe_ids|
      not_remove_order_ids = Notification.where(appeals_id: dupe_ids).group(:appeals_id, :appeals_type).having('COUNT(*) > 1').pluck('MIN(id)')
      Notification.where(appeals_id: dupe_ids).where.not(id: not_remove_order_ids).destroy_all
    end
  end
end