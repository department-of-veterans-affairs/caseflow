class RemoveActionFromTasks < ActiveRecord::Migration[5.1]
  def change
    safety_assured { remove_column :tasks, :action, :text }
  end
end
