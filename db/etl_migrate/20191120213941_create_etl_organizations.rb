class CreateEtlOrganizations < ActiveRecord::Migration[5.1]
  def change
    create_table :organizations, comment: "Copy of Organizations table" do |t|
      t.datetime "created_at"
      t.string "name"
      t.string "participant_id", comment: "Organizations BGS partipant id"
      t.string "role", comment: "Role users in organization must have, if present"
      t.string "type", comment: "Single table inheritance"
      t.datetime "updated_at"
      t.string "url", comment: "Unique portion of the organization queue url"
      t.index ["url"], unique: true
      t.index ["created_at"]
      t.index ["updated_at"]
    end

    create_table "organizations_users", comment: "Copy of OrganizationUsers table" do |t|
      t.boolean "admin", default: false
      t.datetime "created_at"
      t.integer "organization_id"
      t.datetime "updated_at"
      t.integer "user_id"
      t.index ["organization_id"]
      t.index ["user_id", "organization_id"], unique: true
      t.index ["created_at"]
      t.index ["updated_at"]
    end
  end
end
