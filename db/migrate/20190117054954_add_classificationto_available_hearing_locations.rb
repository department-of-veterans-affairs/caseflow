class AddClassificationtoAvailableHearingLocations < ActiveRecord::Migration[5.1]
  def change
    add_column :available_hearing_locations, :classification, :string
    add_column :available_hearing_locations, :facility_type, :string
  end
end
