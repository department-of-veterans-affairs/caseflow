class AddVacolsIdToUsers < ActiveRecord::Migration
  def change
    # vacols_id maps to the `STAFKEY` in the STAFF table
    add_column :users, :vacols_id, :string
  end
end
