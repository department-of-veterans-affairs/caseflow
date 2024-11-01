class CreateEtlUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users, comment: "Combined Caseflow/VACOLS user lookups" do |t|
      t.timestamps null: false, comment: "Default created_at/updated_at for the ETL record"
      t.index ["created_at"]
      t.index ["updated_at"]

      # caseflow attributes
      t.integer "user_id", null: false, comment: "ID of the User"
      t.string "css_id", null: false, limit: 20, comment: "CSEM (Active Directory) username"
      t.string "email", limit: 255, comment: "CSEM email"
      t.string "full_name", limit: 255, comment: "CSEM full name"
      t.datetime "last_login_at"
      t.string "roles", array: true
      t.string "selected_regional_office", limit: 255, comment: "CSEM regional office"
      t.string "station_id", null: false, limit: 20, comment: "CSEM station"
      t.string "status", default: "active", limit: 20, comment: "Whether or not the user is an active user of caseflow"
      t.datetime "status_updated_at", comment: "When the user's status was last updated"

      # VACOLS attributes
      t.string "sactive", limit: 1, null: false
      t.string "sattyid", limit: 20
      t.string "slogid", null: false, limit: 20
      t.string "stafkey", null: false, limit: 20
      t.string "svlj", limit: 1

      t.index "upper((css_id)::text)", unique: true
      t.index ["status"]
    end
  end
end
