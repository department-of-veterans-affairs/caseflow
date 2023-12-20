class AddDescriptionToCavcDashboardIssues < Caseflow::Migration
  def change
    add_column :cavc_dashboard_issues, :issue_description, :string
  end
end
