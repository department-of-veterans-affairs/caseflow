class RemoveTasksCompletedAtColumn < ActiveRecord::Migration[5.1]
  def up
    safety_assured do
      remove_column :tasks, :completed_at
    end
  end

  def down
    safety_assured do
      add_column :tasks, :completed_at, :datetime
      execute "UPDATE tasks SET completed_at=closed_at"
    end
  end
end
