class AddFirstAndLastNameToCachedUsers < Caseflow::Migration
  def change
    add_column :cached_user_attributes, :snamef, :string
    add_column :cached_user_attributes, :snamel, :string
  end
end
