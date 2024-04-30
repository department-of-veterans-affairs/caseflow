class CreateEtlPeople < ActiveRecord::Migration[5.1]
  def change
    create_table :people, comment: "Copy of People table" do |t|
      t.datetime "created_at", null: false
      t.date "date_of_birth"
      t.string "first_name", limit: 50, comment: "Person first name, cached from BGS"
      t.string "last_name", limit: 50, comment: "Person last name, cached from BGS"
      t.string "middle_name", limit: 50, comment: "Person middle name, cached from BGS"
      t.string "name_suffix", limit: 20, comment: "Person name suffix, cached from BGS"
      t.string "participant_id", null: false, limit: 20
      t.datetime "updated_at", null: false
      t.index ["participant_id"]
      t.index ["created_at"]
      t.index ["updated_at"]
    end
  end
end
