class CreateOrganizationPermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :organization_permissions do |t|
      t.references :organization, foreign_key: true, null: false
      t.string :permission, null: false
      t.string :description, null: false
      t.boolean :enabled, null: false, default: false

      t.references :parent_permission, foreign_key: { to_table: :organization_permissions }

      t.timestamps
    end
  end
end
