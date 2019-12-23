class AddEmailAddressToPerson < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :email_address, :string
  end
end
