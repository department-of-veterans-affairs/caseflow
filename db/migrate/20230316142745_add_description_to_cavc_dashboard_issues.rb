class AddDescriptionToCavcDashboardIssues < Caseflow::Migration
  def change
    add_column :cavc_dashboard_issues, :description, :string
  end
end
