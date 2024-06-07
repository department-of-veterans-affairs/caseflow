class CreateOrganizationPermissions < Caseflow::Migration
  def change
    create_table :organization_permissions do |t|
      t.string :permission, null: false, comment: "Developer friendly value"
      t.string :description, null: false, comment: "UX display value"
      t.boolean :enabled, null: false, default: false, comment: "Whether permission is enabled or disabled"

      t.references :organization, foreign_key: true, null: false, index: false,
        comment: "Foreign key to organizations table"
      t.references :parent_permission, foreign_key: { to_table: :organization_permissions }, index: false,
        comment: "Foreign key to self"

      t.timestamps
    end

    add_safe_index :organization_permissions, :organization_id
    add_safe_index :organization_permissions, :parent_permission_id
  end
end
