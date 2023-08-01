class AddRemediationNotesToCaseflowStuckRecords < Caseflow::Migration
  def change
    add_column :caseflow_stuck_records, :remediation_notes, :text, comment: "Brief description of the encountered issue and remediation strategy"
  end
end
