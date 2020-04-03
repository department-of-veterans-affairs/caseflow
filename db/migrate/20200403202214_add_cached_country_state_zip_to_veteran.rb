class AddCachedCountryStateZipToVeteran < ActiveRecord::Migration[5.2]
  def change
    add_column :veterans, :country, :string, comment: "Cached copy of veteran's country from BGS"
    add_column :veterans, :state, :string, comment: "Cached copy of veteran's state from BGS"
    add_column :veterans, :zip_code, :string, comment: "Cached copy of veteran's zipcode from BGS"
  end
end
