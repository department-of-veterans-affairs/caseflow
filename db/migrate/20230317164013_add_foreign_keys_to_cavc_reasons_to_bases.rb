class AddForeignKeysToCavcReasonsToBases < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key "cavc_reasons_to_bases", "users", column: "created_by_id", name: "cavc_reasons_to_bases_created_by_id_fk", validate: false
    add_foreign_key "cavc_reasons_to_bases", "users", column: "updated_by_id", name: "cavc_reasons_to_bases_updated_by_id_fk", validate: false
  end
end
