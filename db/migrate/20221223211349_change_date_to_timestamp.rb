class ChangeDateToTimestamp < ActiveRecord::Migration[5.2]
  def up
    safety_assured {change_column :notifications, :event_date, :timestamp}
  end

  def down
    safety_assured {change_column :notifications, :event_date, :date}
  end
end
