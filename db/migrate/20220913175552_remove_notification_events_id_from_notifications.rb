class RemoveNotificationEventsIdFromNotifications < Caseflow::Migration
  # Purpose: Removing duplicate column. notification_events_id is the same as event_type
  #
  # Params: None
  #
  # Returns: None
  def change
    safety_assured { remove_column :notifications, :notification_events_id, :bigint }
  end
end
