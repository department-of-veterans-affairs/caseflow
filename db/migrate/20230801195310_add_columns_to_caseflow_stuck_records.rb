class AddColumnsToCaseflowStuckRecords < Caseflow::Migration
  def change
    add_column :caseflow_stuck_records, :remediated, :boolean, default: false, null: false, comment: "Reflects if the stuck record has been reviewed and fixed"
    add_column :caseflow_stuck_records, :remediation_notes, :text, comment: "Brief description of the encountered issue and remediation strategy"
    add_column :caseflow_stuck_records, :updated_at, :datetime, comment: "The time an update occurred on the record"
  end
end
