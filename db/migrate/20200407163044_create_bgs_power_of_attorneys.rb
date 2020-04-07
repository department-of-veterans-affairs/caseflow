class CreateBgsPowerOfAttorneys < ActiveRecord::Migration[5.2]
  def change
    create_table :bgs_power_of_attorneys, comment: "Power of Attorney (POA) cached from BGS" do |t|
      t.timestamps null: false, comment: "Standard created_at/updated_at timestamps"
      t.datetime "last_synced_at", comment: "The last time BGS was checked"
      t.string "authzn_change_clmant_addrs_ind", null: false, comment: "Authorization for POA to change claimant address"
      t.string "authzn_poa_access_ind", null: false, comment: "Authorization for POA access"
      t.string "legacy_poa_cd", comment: "Legacy POA code"
      t.string "representative_name", null: false, comment: "POA name"
      t.string "representative_type", null: false, comment: "POA type"
      t.string "poa_participant_id", null: false, comment: "POA participant ID -- use as FK to people"
      t.string "claimant_participant_id", null: false, comment: "Claimant participant ID -- use as FK to claimants"
      t.string "file_number", null: false, comment: "Claimant file number"

      t.index ["claimant_participant_id", "file_number"], unique: true, name: "bgs_poa_pid_fn_unique_idx"
      t.index ["created_at"]
      t.index ["updated_at"]
      t.index ["last_synced_at"]
      t.index ["representative_name"]
      t.index ["representative_type"]
      t.index ["poa_participant_id"]
    end
  end
end
