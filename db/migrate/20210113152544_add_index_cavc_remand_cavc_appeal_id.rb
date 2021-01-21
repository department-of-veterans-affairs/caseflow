class AddIndexCavcRemandCavcAppealId < Caseflow::Migration
  def change
    add_safe_index :cavc_remands, [:remand_appeal_id]
  end
end
