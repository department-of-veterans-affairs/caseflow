class UpdateNotificationContentColumn < Caseflow::Migration
  def up
    change_column_null :notifications, :notification_content, true
  end
  def down
    change_column_null :notifications, :notification_content, false
  end
end