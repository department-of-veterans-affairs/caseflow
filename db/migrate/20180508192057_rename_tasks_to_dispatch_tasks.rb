class RenameTasksToDispatchTasks < ActiveRecord::Migration[5.1]
  def change
    rename_table :tasks, :dispatch_tasks
  end
end
