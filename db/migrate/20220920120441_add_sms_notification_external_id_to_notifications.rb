class AddSmsNotificationExternalIdToNotifications < Caseflow::Migration
  def change
    add_column :notifications, :sms_notification_external_id, :string, comment: "VA Notify Notification Id for the sms notification send through their API "
  end
end
