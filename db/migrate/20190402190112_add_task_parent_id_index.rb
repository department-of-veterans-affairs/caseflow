class AddTaskParentIdIndex < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :tasks, :parent_id, algorithm: :concurrently
  end
end
