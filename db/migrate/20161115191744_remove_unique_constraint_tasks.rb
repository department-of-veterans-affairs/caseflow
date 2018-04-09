class RemoveUniqueConstraintTasks < ActiveRecord::Migration[5.1]
  def change
  	remove_index(:tasks, column: [:appeal_id, :type])
  end
end
