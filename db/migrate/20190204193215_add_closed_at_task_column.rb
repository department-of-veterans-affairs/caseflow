class AddClosedAtTaskColumn < ActiveRecord::Migration[5.1]
  def up
    safety_assured do
      add_column :tasks, :closed_at, :datetime
      execute "UPDATE tasks SET closed_at=completed_at"
    end
  end

  def down; end
end
