class CreateOrganizationPermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :organization_permissions do |t|
      t.references :organization, foreign_key: true, null: false, comment: "Foreign key to organizations table"
      t.string :permission, null: false, comment: "Developer friendly value"
      t.string :description, null: false, comment: "UX display value"
      t.boolean :enabled, null: false, default: false, comment: "Whether permission is enabled or disabled"

      t.references :parent_permission, foreign_key: { to_table: :organization_permissions },
        comment: "Foreign key to self"

      t.timestamps
    end
  end
end
