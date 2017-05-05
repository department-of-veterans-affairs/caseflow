class AddPreparedAtToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :prepared_at, :datetime
  end
end
