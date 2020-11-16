class CavcRemandUpdatedByNullable < Caseflow::Migration
  def change
    safety_assured { remove_column :cavc_remands, :updated_by_id, :bigint, null: false, comment: "User that updated this record. For MDR remands, judgement and mandate dates will be added after the record is first created." }
    add_column  :cavc_remands, :updated_by_id, :bigint, comment: "User that updated this record. For MDR remands, judgement and mandate dates will be added after the record is first created."
  end
end
