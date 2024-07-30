# Public: Active migration to handle the Migration and Rollback of making the
# column noticiations.notification_content nullable

class UpdateNotificationContentColumn < Caseflow::Migration
  
  # Purpose: Method update the notifications.notification_content column to be nullable
  # when this migration is apllied
  #
  # Params: None
  #
  # Returns: None
  def up
    change_column_null :notifications, :notification_content, true
  end

  # Purpose: Method update the notifications.notification_content column to not be nullable
  # when this migration is rollbacked
  #
  # Params: None
  #
  # Returns: None
  def down
    change_column_null :notifications, :notification_content, false
  end
end