class CreateCavcSelectionBases < Caseflow::Migration
  def change
    create_table :cavc_selection_bases do |t|
      t.string :basis_for_selection
      t.string :category
      t.datetime :created_at
      t.datetime :updated_at
      t.bigint :created_by
      t.bigint :updated_by
    end
  end
end
