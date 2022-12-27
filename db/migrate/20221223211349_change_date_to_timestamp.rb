class ChangeDateToTimestamp < ActiveRecord::Migration[5.2]
  def change
    safety_assured {change_column :notifications, :event_date, :timestamp}
  end
end
