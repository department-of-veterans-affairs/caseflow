class AddSmsNotificationExternalIdToNotifications < ActiveRecord::Migration[5.2]
  def change
    add_column :notifications, :sms_notification_external_id, :string
  end
end
