class CreateBgsAttorneys < ActiveRecord::Migration[5.2]
  def change
    create_table :bgs_attorneys, comment: "Attorney data cached from BGS — used for claimants" do |t|
      t.timestamps null: false, comment: "Standard created_at/updated_at timestamps"
      t.datetime "last_synced_at", comment: "The last time BGS was checked"
      t.string "participant_id", null: false, comment: "Participant ID"
      t.string "name", null: false, comment: "Name"
      t.string "type", null: false, comment: "Type of Record"
      t.string "legacy_poa_cd", comment: "Legacy POA code"

      t.index ["created_at"]
      t.index ["updated_at"]
      t.index ["last_synced_at"]
      t.index ["participant_id"], unique: true
      t.index ["name"]
    end
  end
end
