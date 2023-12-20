class AddCompletedByToTaskModel < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_column :tasks, :completed_by_id, :integer, comment: "ID of user that marked task complete"
  end
end
