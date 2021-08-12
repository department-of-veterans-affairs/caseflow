class AddFirstAndLastNameToCachedUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :cached_user_attributes, :snamef, :string
    add_column :cached_user_attributes, :snamel, :string
  end
end
