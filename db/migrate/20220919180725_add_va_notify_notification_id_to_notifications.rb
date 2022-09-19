class AddVaNotifyNotificationIdToNotifications < Caseflow::Migration
  # Purpose: Adding va_notify_notification_id to notifications table so that it can be captured from response from API call
  #
  # Params: None
  #
  # Returns: None
  def change
    add_column :notifications, :va_notify_notification_id, :string, comment: "ID of notification from VA Notify"
  end
end
