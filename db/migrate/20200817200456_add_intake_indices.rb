class AddIntakeIndices < Caseflow::Migration
  def change
    add_safe_index :intakes, [:detail_type, :detail_id]
  end
end
