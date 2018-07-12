class AddOnHoldDurationToTasks < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :on_hold_duration, :integer
  end
end
