class AddIndexesToBatchProcesses < Caseflow::Migration
  def change
    add_safe_index :batch_processes, [:state], name: "index_batch_processes_on_state", unique: false
    add_safe_index :batch_processes, [:batch_type], name: "index_batch_processes_on_batch_type", unique: false
    add_safe_index :batch_processes, [:records_failed], name: "index_batch_processes_on_records_failed", unique: false
  end
end
