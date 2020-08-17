class AddIntakeIndices < Caseflow::Migration
  def change
    add_safe_index :intakes, [:detail_type, :detail_id], name: :index_intakes_on_detail_type_and_detail_id
  end
end
