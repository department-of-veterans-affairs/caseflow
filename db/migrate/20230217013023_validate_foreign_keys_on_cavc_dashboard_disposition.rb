class ValidateForeignKeysOnCavcDashboardDisposition < Caseflow::Migration
  def change
    validate_foreign_key "cavc_dispositions_to_reasons", name: "cavc_dispositions_to_reasons_created_by_id_fk"
    validate_foreign_key "cavc_dispositions_to_reasons", name: "cavc_dispositions_to_reasons_updated_by_id_fk"
  end
end
