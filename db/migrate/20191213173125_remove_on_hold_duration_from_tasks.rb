class RemoveOnHoldDurationFromTasks < ActiveRecord::Migration[5.1]
  def change
    safety_assured { remove_column :tasks, :on_hold_duration, :int }
  end
end
