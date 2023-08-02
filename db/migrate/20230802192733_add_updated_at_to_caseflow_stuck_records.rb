class AddUpdatedAtToCaseflowStuckRecords < Caseflow::Migration
  def change
    add_column :caseflow_stuck_records, :updated_at, :datetime, comment: "The time an update occurred on the record"
  end
end
