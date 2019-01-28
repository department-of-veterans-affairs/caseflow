class ChangeHearingScheduledTime < ActiveRecord::Migration[5.1]
  def change
    change_column_null(:hearings, :scheduled_time, false)
  end
end
