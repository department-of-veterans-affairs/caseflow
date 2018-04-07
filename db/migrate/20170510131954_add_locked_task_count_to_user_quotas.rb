class AddLockedTaskCountToUserQuotas < ActiveRecord::Migration[5.1]
  def change
    add_column :user_quotas, :locked_task_count, :integer
  end
end
