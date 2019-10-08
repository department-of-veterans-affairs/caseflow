class AddTasksIndexes < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :tasks, :status, algorithm: :concurrently
    add_index :tasks, :type, algorithm: :concurrently
  end
end
