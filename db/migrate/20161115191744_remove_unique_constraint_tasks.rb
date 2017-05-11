class RemoveUniqueConstraintTasks < ActiveRecord::Migration
  def change
  	remove_index(:tasks, column: [:appeal_id, :type])
  end
end
