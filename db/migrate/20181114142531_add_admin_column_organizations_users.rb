class AddAdminColumnOrganizationsUsers < ActiveRecord::Migration[5.1]
  def change
    safety_assured { add_column :organizations_users, :admin, :boolean, default: false }
  end
end
