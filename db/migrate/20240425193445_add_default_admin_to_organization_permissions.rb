class AddDefaultAdminToOrganizationPermissions < ActiveRecord::Migration[6.1]
  def change
    add_column :organization_permissions, :default_for_admin, :boolean, null: false, default: false
  end
end
