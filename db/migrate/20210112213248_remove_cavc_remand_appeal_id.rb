class RemoveCavcRemandAppealId < Caseflow::Migration
  def up
    safety_assured { remove_column :cavc_remands, :appeal_id, :bigint, comment: "Appeal that CAVC has remanded" }
  end

  def down
    add_column  :cavc_remands, :appeal_id, :bigint, comment: "Appeal that CAVC has remanded"
    safety_assured { execute "UPDATE cavc_remands SET appeal_id = source_appeal_id" }
    change_column_null  :cavc_remands, :appeal_id, false
    add_safe_index :cavc_remands, [:appeal_id]
  end
end
