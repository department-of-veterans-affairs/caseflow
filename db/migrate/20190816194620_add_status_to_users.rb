class AddStatusToUsers < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_column :users, :status, :string, comment: "Whether or not the user is an active user of caseflow"
    add_column :users, :status_updated_at, :datetime, comment: "When the user's status was last updated"
    add_index :users, :status, algorithm: :concurrently

    User.update_all(status: "active")
  end
end
