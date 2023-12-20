class AddCavcRemandCavcAppealId < Caseflow::Migration
  def up
    add_column  :cavc_remands, :remand_appeal_id, :bigint, comment: "Appeal created by this CAVC Remand"
  end

  def down
    remove_column  :cavc_remands, :remand_appeal_id, :bigint, comment: "Court remand appeal created by this entry"
  end
end
