class AddClosedAtTaskColumn < ActiveRecord::Migration[5.1]
  def up
    safety_assured do
      add_column :tasks, :closed_at, :datetime
      Task.find_each { |t| t.update!(closed_at: t.completed_at) }
    end
  end

  def down
    safety_assured do
      remove_column :tasks, :closed_at
    end
  end
end
