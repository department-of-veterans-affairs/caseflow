class AddEmailAddressToVeteran < ActiveRecord::Migration[5.1]
  def change
    add_column :veterans, :email_address, :string
  end
end
