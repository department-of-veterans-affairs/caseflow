class AddAppealTimestamps < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_column :appeals, :appeal_created_at, :datetime, null: false
    add_column :appeals, :appeal_updated_at, :datetime, null: false

    add_index :appeals, :appeal_created_at, algorithm: :concurrently
    add_index :appeals, :appeal_updated_at, algorithm: :concurrently
  end
end
