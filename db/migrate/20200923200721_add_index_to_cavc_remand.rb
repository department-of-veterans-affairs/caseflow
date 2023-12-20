class AddIndexToCavcRemand < Caseflow::Migration
  def change
    add_safe_index :cavc_remands, [:appeal_id]
  end
end
