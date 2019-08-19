class AddDefaultValueToStatus < ActiveRecord::Migration[5.1]
  def up
    change_column_default :users, :status, "active"
  end

  def down
    change_column_default :users, :status, nil
  end
end
