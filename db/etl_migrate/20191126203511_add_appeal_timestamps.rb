class AddAppealTimestamps < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_column :appeals, :appeal_created_at, :datetime, null: false, comment: "appeals.created_at"
    add_column :appeals, :appeal_updated_at, :datetime, null: false, comment: "appeals.updated_at"
    change_column_comment :appeals, :created_at, "Creation timestamp for the ETL record"
    change_column_comment :appeals, :updated_at, "Updated timestamp for the ETL record"

    add_index :appeals, :appeal_created_at, algorithm: :concurrently
    add_index :appeals, :appeal_updated_at, algorithm: :concurrently
  end
end
