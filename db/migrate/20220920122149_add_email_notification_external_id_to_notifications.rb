class AddEmailNotificationExternalIdToNotifications < Caseflow::Migration
  def change
    add_column :notifications, :email_notification_external_id, :string, comment: "VA Notify Notification Id for the email notification send through their API "
  end
end
