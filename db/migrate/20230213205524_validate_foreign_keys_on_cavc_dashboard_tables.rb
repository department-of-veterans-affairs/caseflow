class ValidateForeignKeysOnCavcDashboardTables < Caseflow::Migration
  def change
    validate_foreign_key "cavc_dashboard_dispositions", name: "cavc_dashboard_dispositions_created_by_id_fk"
    validate_foreign_key "cavc_dashboard_dispositions", name: "cavc_dashboard_dispositions_updated_by_id_fk"
    validate_foreign_key "cavc_dashboard_issues", name: "cavc_dashboard_issues_created_by_id_fk"
    validate_foreign_key "cavc_dashboard_issues", name: "cavc_dashboard_issues_updated_by_id_fk"
    validate_foreign_key "cavc_dashboards", name: "cavc_dashboards_created_by_id_fk"
    validate_foreign_key "cavc_dashboards", name: "cavc_dashboards_updated_by_id_fk"
  end
end
