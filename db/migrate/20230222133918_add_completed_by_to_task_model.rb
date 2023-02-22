class AddCompletedByToTaskModel < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_reference :tasks, :completed_by, foreign_key: { :to_table=> :users }, index: false
    add_index :tasks, :completed_by_id, algorithm: :concurrently
  end
end
