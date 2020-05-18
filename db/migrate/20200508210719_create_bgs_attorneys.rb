class CreateBgsAttorneys < ActiveRecord::Migration[5.2]
  def change
    create_table :bgs_attorneys, comment: "Cache of unique BGS attorney data — used for adding claimants to cases pulled from POA data" do |t|
      t.timestamps null: false, comment: "Standard created_at/updated_at timestamps"
      t.datetime "last_synced_at", comment: "The last time BGS was checked"
      t.string "participant_id", null: false, comment: "Participant ID"
      t.string "name", null: false, comment: "Name"
      t.string "record_type", null: false, comment: "Known types: #{record_types.join(', ')}"

      t.index ["created_at"]
      t.index ["updated_at"]
      t.index ["last_synced_at"]
      t.index ["participant_id"], unique: true
      t.index ["name"]
    end
  end

  def record_types
    [
      "POA State Organization",
      "POA National Organization",
      "POA Attorney",
      "POA Agent",
      "POA Local/Regional Organization"
    ]
  end
end
