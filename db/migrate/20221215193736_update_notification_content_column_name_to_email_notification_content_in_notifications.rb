class UpdateNotificationContentColumnNameToEmailNotificationContentInNotifications < Caseflow::Migration
  def up
    rename_column :notifications, :notification_content, :email_notification_content, comment: "Full Email Text Content of Notification"
  end

  def down
    rename_column :notifications, :email_notification_content, :notification_content, comment: "Full Text Content of Notification"
  end
end
