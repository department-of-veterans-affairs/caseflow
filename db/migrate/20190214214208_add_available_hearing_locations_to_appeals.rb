class AddAvailableHearingLocationsToAppeals < ActiveRecord::Migration[5.1]
  def change
    change_column_null :available_hearing_locations, :veteran_file_number, true
    add_column :available_hearing_locations, :appeal_id, :integer, null: true
    add_column :available_hearing_locations, :appeal_type, :string, null: true
    add_column :legacy_appeals, :closest_regional_office, :string
    add_column :appeals, :closest_regional_office, :string
  end
end
