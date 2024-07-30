class AddForeignKeysToCavcDashboardDisposition < Caseflow::Migration
  def change
    add_foreign_key "cavc_dispositions_to_reasons", "users", column: "created_by_id", name: "cavc_dispositions_to_reasons_created_by_id_fk", validate: false
    add_foreign_key "cavc_dispositions_to_reasons", "users", column: "updated_by_id", name: "cavc_dispositions_to_reasons_updated_by_id_fk", validate: false
  end
end
