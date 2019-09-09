class AddVacateTypeToPostDecisionMotion < ActiveRecord::Migration[5.1]
  def change
    add_column :post_decision_motions, :vacate_type, :string, comment: "Granted motion to vacate can be either Straight Vacate and Readjudication or Vacate and De Novo."
  end
end
