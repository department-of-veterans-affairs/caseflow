class AddSmsNotificationContentToNotifications < Caseflow::Migration
  def change
<<<<<<< HEAD
    add_column :notifications, :sms_notification_content, :text, null: true, comment: "Full SMS Text Content of Notification"
=======
    add_column :notifications, :sms_notification_content, :string, null: true, comment: "Full SMS Text Content of Notification"
>>>>>>> master
  end
end
