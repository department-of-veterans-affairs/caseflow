class AddPreviousToTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks, :previous, :jsonb, default: [], array: true
  end
end
