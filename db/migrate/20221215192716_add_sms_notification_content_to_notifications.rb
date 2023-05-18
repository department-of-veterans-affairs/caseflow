class AddSmsNotificationContentToNotifications < Caseflow::Migration
  def change
    add_column :notifications, :sms_notification_content, :string, null: true, comment: "Full SMS Text Content of Notification"
  end
end
