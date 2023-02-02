class CreateCavcDashboardIssues < Caseflow::Migration
  def change
    create_table :cavc_dashboard_issues do |t|
    	t.references :cavc_remand, foreign_key: true, comment: "ID of the associated CAVC remand"
    	t.bigint :cavc_remands_id
      t.string :benefit_type
      t.string :issue_category
      t.datetime :created_at
      t.datetime :updated_at
      t.bigint :created_by
      t.bigint :updated_by
    end
  end
end
