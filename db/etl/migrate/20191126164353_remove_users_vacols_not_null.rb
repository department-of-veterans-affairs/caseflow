class RemoveUsersVacolsNotNull < ActiveRecord::Migration[5.1]
  def change
    change_column_null(:users, :sactive, true)
    change_column_null(:users, :slogid, true)
    change_column_null(:users, :stafkey, true)
  end
end
