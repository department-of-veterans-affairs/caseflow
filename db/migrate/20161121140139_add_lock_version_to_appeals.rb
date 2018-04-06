class AddLockVersionToAppeals < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :lock_version, :integer
  end
end
