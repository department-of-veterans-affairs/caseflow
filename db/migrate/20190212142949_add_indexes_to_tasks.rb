class AddIndexesToTasks < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    ActiveRecord::Base.connection.execute "SET statement_timeout = 1800000" # 30 minutes

    add_index :tasks, [:appeal_type, :appeal_id], algorithm: :concurrently
    add_index :tasks, [:assigned_to_type, :assigned_to_id], algorithm: :concurrently
  ensure
    ActiveRecord::Base.connection.execute "SET statement_timeout = 30000" # 30 seconds
  end
end
