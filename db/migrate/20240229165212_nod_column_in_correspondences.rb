class NodColumnInCorrespondences < Caseflow::Migration
  def change
    safety_assured do
      add_column :correspondences, :nod, :boolean, null: false, default: false, comment: 'NOD (Notice of Disagreement)'
    end
  end
end
