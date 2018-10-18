class UserOrganizationJoinTable < ActiveRecord::Migration[5.1]
  def change
    create_table :organizations_users do |t|
      t.column :organization_id, :integer
      t.column :user_id, :integer
      t.index :organization_id
      t.index [:user_id, :organization_id], unique: true
    end
  end
end
