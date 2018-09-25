class CreatePersons < ActiveRecord::Migration[5.1]
  def change
    create_table :people do |t|
      t.string :participant_id, null: false
      t.date :date_of_birth
      t.timestamps null: false
    end
  end
end
