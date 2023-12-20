class AddCancelledByIdToTasks < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks, :cancelled_by_id, :integer, comment: "ID of user that cancelled the task. Backfilled from versions table. Can be nil if task was cancelled before this column was added or if there is no user logged in when the task is cancelled"
  end
end