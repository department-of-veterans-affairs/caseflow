class CreateOrganizationUserPermissions < ActiveRecord::Migration[6.1]
  include Caseflow::Migrations::AddIndexConcurrently

  def change
    create_table :organization_user_permissions do |t|
      t.references :organizations_user, foreign_key: true, null: false, index: false,
        comment: "Foreign key to organizations_user table"
      t.references :organization_permission, foreign_key: true, null: false, index: false,
        comment: "Foreign key to organization_permission table"
      t.boolean :permitted, null: false, default: false, comment: "Whether or not the organization_user has the given permission enabled"

      t.timestamps
    end

    add_safe_index :organization_user_permissions, :organizations_user_id
    add_safe_index :organization_user_permissions, :organization_permission_id, name: "index_on_organization_permission_id"
  end
end
