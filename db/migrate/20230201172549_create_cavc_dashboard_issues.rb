class CreateCavcDashboardIssues < Caseflow::Migration
  def change
    create_table :cavc_dashboard_issues do |t|
    	t.references :cavc_remand, foreign_key: true, comment: "ID of the associated CAVC remand"
      t.string :benefit_type
      t.string :issue_category
      t.datetime :created_at
      t.datetime :updated_at
      t.bigint :created_by_id
      t.bigint :updated_by_id
    end
  end
end
