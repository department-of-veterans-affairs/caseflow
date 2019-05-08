class AddTaskIdToDistributedCases < ActiveRecord::Migration[5.1]
  def change
    add_column :distributed_cases, :task_id, :integer
  end
end
