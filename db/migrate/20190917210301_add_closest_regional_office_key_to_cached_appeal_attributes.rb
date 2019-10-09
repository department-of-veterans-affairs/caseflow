class AddClosestRegionalOfficeKeyToCachedAppealAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :cached_appeal_attributes, :closest_regional_office_key, :string, comment: "Closest regional office to the veteran in 4 character key"
  end
end
