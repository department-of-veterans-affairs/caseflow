class AddAvailableHearingLocationsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :available_hearing_locations do |t|
      t.string :veteran_file_number, null: false, index: true
      t.float :distance
      t.string :facility_id
      t.string :name
      t.string :address
      t.timestamps
    end
  end
end
