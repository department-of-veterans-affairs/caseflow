class IndexDistributedCasesOnCaseId < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :distributed_cases, :case_id, unique: true, algorithm: :concurrently
  end
end
