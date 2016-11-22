class AddLockVersionToAppeals < ActiveRecord::Migration
  def change
    add_column :tasks, :lock_version, :integer
  end
end
