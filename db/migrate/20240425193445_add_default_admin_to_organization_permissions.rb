class AddDefaultAdminToOrganizationPermissions < Caseflow::Migration
  def change
    add_column :organization_permissions, :default_for_admin, :boolean, null: false, default: false
  end
end
