class AddRemediatedToCaseflowStuckRecords < Caseflow::Migration
  def change
    add_column :caseflow_stuck_records, :remediated, :boolean, default: false, comment: "Reflects if the stuck record has been reviewed and fixed"
  end
end
