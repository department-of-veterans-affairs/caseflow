class AddClosestRegionalOfficeCityToCachedAppealAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :cached_appeal_attributes, :closest_regional_office_city, :string, comment: "Closest regional office to the veteran"
  end
end
