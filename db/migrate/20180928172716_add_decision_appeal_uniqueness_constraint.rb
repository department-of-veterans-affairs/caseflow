class AddDecisionAppealUniquenessConstraint < ActiveRecord::Migration[5.1]
  safety_assured

  def change
    remove_index :decisions, [:appeal_id]
    add_index :decisions, [:appeal_id], unique: true
  end
end
