class AddLocationDataToHearings < ActiveRecord::Migration[5.1]
  def change
    create_table :hearing_locations do |t|
      t.integer :hearing_id
      t.string :hearing_type
      t.float :distance
      t.string :facility_id
      t.string :name
      t.string :address
      t.string :city
      t.string :state
      t.string :zip_code
      t.string :facility_type
      t.string :classification
      t.timestamps
    end
  end
end
