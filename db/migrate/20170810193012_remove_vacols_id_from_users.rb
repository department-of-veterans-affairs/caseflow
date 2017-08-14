class RemoveVacolsIdFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :vacols_id, :integer
  end
end
