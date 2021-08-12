class AddFirstAndLastNameToCachedUsers < Caseflow::Migration
  # These columns store the User's first and last name values coming from VACOLS
  def change
    add_column :cached_user_attributes, :snamef, :string
    add_column :cached_user_attributes, :snamel, :string
  end
end
