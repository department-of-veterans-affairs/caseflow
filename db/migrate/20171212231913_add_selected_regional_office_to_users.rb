class AddSelectedRegionalOfficeToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :selected_regional_office, :string
  end
end
