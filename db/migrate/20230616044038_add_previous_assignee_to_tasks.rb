class AddPreviousAssigneeToTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks, :previous_assignee, :string
  end
end
