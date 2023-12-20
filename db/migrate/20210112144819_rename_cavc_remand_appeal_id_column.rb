class RenameCavcRemandAppealIdColumn < Caseflow::Migration
  def up
    add_column  :cavc_remands, :source_appeal_id, :bigint, comment: "Appeal that CAVC has remanded"
    safety_assured { execute "UPDATE cavc_remands SET source_appeal_id = appeal_id" }
    change_column_null  :cavc_remands, :source_appeal_id, false
  end

  def down
    remove_column :cavc_remands, :source_appeal_id, :bigint, comment: "Appeal that CAVC has remanded"
  end
end
