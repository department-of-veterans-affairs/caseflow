class AddNodToCorrespondence < Caseflow::Migration
  def change
    add_column :correspondences, :nod, :boolean, default: false, null: false
  end
end
