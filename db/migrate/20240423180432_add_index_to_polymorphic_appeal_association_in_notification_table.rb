class AddIndexToPolymorphicAppealAssociationInNotificationTable < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :notifications,
              [:notifiable_type, :notifiable_id],
              name: "index_notifications_on_notifiable_type_and_notifiable_id",
              algorithm: :concurrently
  end
end
