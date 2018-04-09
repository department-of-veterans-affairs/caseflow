class AddPreparedAtToTasks < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :prepared_at, :datetime
  end
end
