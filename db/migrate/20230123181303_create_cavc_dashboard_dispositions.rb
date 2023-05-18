class CreateCavcDashboardDispositions < Caseflow::Migration
  def change
    create_table :cavc_dashboard_dispositions do |t|
      t.references :cavc_remand, foreign_key: true, comment: "ID of the associated CAVC remand"
      t.bigint     :request_issue_id, comment: "ID for a request issue that was filed with the CAVC Remand"
      t.bigint     :cavc_dashboard_issue_id, commment: "ID for an issue that was added in the CAVC Dashboard"
      t.string     :disposition, comment: "The disposition of the issue"
      t.bigint     :created_by_id, comment: "The ID for the user that created the record"
      t.bigint     :updated_by_id, comment: "The ID for the user that most recently changed the record"
      t.timestamps
    end
  end
end
