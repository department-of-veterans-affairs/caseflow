class RemoveVacolsIdFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :vacols_id
  end
end
