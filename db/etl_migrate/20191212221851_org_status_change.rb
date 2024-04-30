class OrgStatusChange < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_column :organizations, :status, :string, comment: "Whether organization is active, inactive, or in some other Status."
    add_column :organizations, :status_updated_at, :datetime, comment: "Track when organization status last changed."

    add_index :organizations, :status, algorithm: :concurrently
  end
end
