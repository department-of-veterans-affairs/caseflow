class AddPlacedOnHoldAtToTasks < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :placed_on_hold_at, :datetime
  end
end
