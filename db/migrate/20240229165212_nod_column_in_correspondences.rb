class NodColumnInCorrespondences < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_column :correspondences, :nod, :boolean, null: false, default: false, comment: 'NOD (Notice of Disagreement)'
    end
  end
end
