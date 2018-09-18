class AddParentIdToTasks < ActiveRecord::Migration[5.1]
  def change
  	add_column :tasks, :parent_id, :integer
  end
end
