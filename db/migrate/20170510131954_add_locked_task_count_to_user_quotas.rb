class AddLockedTaskCountToUserQuotas < ActiveRecord::Migration
  def change
    add_column :user_quotas, :locked_task_count, :integer
  end
end
