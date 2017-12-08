class AddRegionalOfficeToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :regional_office, :string
  end
end
