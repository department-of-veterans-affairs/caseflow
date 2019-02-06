class AddClosedAtTaskColumn < ActiveRecord::Migration[5.1]
  def up
    safety_assured do
      remove_column(:tasks, :closed_at) if column_exists?(:tasks, :closed_at)
      add_column(:tasks, :closed_at, :timestamp)
      execute("UPDATE tasks SET closed_at=completed_at")
    end
  end

  def down
    safety_assured do
      remove_column(:tasks, :closed_at)
    end
  end
end
