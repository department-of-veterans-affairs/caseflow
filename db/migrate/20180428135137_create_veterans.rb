class CreateVeterans < ActiveRecord::Migration[5.1]
  safety_assured

  def change
    create_table :veterans do |t|
      t.string :file_number, null: false
      t.string :participant_id
    end

    add_index(:veterans, [:file_number], unique: true)
    add_index(:veterans, [:participant_id], unique: true)
  end
end
