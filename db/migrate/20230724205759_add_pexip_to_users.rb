class AddPexipToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :pexip, :boolean
  end
end
