class AddRegionDetailsToVeterans < ActiveRecord::Migration[6.1]
  def change
    add_column :veterans, :state_of_residence, :text, comment: "The most recently known state of residence of the veteran"
    add_column :veterans, :country_of_residence, :text, comment: "The most recently known country of residence of the veteran"
    add_column :veterans, :residence_location_last_checked_at, :timestamptz, null: true, comment: "The most recent time the veteran residence location was checked"
  end
end
