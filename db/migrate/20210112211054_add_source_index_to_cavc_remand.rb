class AddSourceIndexToCavcRemand < Caseflow::Migration
  def change
    add_safe_index :cavc_remands, [:source_appeal_id]
  end
end
