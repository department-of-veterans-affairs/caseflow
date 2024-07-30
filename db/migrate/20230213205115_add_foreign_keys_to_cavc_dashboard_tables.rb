class AddForeignKeysToCavcDashboardTables < Caseflow::Migration
  def change
    add_foreign_key "cavc_dashboard_dispositions", "users", column: "created_by_id", name: "cavc_dashboard_dispositions_created_by_id_fk", validate: false
    add_foreign_key "cavc_dashboard_dispositions", "users", column: "updated_by_id", name: "cavc_dashboard_dispositions_updated_by_id_fk", validate: false
    add_foreign_key "cavc_dashboard_issues", "users", column: "created_by_id", name: "cavc_dashboard_issues_created_by_id_fk", validate: false
    add_foreign_key "cavc_dashboard_issues", "users", column: "updated_by_id", name: "cavc_dashboard_issues_updated_by_id_fk", validate: false
    add_foreign_key "cavc_dashboards", "users", column: "created_by_id", name: "cavc_dashboards_created_by_id_fk", validate: false
    add_foreign_key "cavc_dashboards", "users", column: "updated_by_id", name: "cavc_dashboards_updated_by_id_fk", validate: false
  end
end
