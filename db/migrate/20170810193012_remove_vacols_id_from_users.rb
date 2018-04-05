class RemoveVacolsIdFromUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :vacols_id, :integer
  end
end
