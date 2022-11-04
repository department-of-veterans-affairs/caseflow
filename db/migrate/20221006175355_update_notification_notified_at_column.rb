class UpdateNotificationNotifiedAtColumn < Caseflow::Migration
  def change
    change_column_null :notifications, :notified_at, true
  end
end
