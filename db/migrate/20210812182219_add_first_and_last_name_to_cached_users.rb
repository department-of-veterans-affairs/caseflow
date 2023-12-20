class AddFirstAndLastNameToCachedUsers < Caseflow::Migration
  def change
    add_column :cached_user_attributes, :snamef, :string, comment: "User's First Name in VACOLS"
    add_column :cached_user_attributes, :snamel, :string, comment: "User's Last Name in VACOLS"
  end
end
