class AddSelectedRegionalOfficeToUsers < ActiveRecord::Migration[5.1]
  def change
  	add_column :users, :selected_regional_office, :string
  end
end
