class AddEmailNotificationExternalIdToNotifications < ActiveRecord::Migration[5.2]
  def change
    add_column :notifications, :email_notification_external_id, :string
  end
end
