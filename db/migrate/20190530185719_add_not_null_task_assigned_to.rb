class AddNotNullTaskAssignedTo < ActiveRecord::Migration[5.1]
  def change
    change_column_null(:tasks, :assigned_to_id, false)
  end
end
