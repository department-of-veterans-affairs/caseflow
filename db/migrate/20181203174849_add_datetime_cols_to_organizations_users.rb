class AddDatetimeColsToOrganizationsUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations_users, :created_at, :datetime
    add_column :organizations_users, :updated_at, :datetime
  end
end
