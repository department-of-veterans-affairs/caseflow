class AddEmailNotificationContentToNotifications < Caseflow::Migration
  def change
    add_column :notifications, :email_notification_content, :string, null: true, comment: "Full Email Text Content of Notification"
  end
end
