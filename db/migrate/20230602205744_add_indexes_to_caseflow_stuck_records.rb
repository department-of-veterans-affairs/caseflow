class AddIndexesToCaseflowStuckRecords < Caseflow::Migration
  def change
    add_safe_index :caseflow_stuck_records, [:record_id], name: "index_caseflow_stuck_records_on_record_id"
    add_safe_index :caseflow_stuck_records, [:record_type], name: "index_caseflow_stuck_records_on_record_type"
  end
end
