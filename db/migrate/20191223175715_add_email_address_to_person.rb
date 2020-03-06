class AddEmailAddressToPerson < ActiveRecord::Migration[5.1]
  def change
    add_column :people, :email_address, :string, comment: "Person email address, cached from BGS"
  end
end
