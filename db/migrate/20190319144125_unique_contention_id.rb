class UniqueContentionId < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    remove_index :request_issues, [:contention_reference_id, :removed_at]
    add_index :request_issues, :contention_reference_id, unique: true, algorithm: :concurrently
  end

  def down
    add_index :request_issues, [:contention_reference_id, :removed_at], unique: true, algorithm: :concurrently
    remove_index :request_issues, :contention_reference_id
  end
end
