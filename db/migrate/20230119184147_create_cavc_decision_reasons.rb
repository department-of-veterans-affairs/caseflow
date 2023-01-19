class CreateCavcDecisionReasons < Caseflow::Migration
  def change
    create_table :cavc_decision_reasons do |t|
      t.string    :decision_reason
      t.integer   :parent_decision_reason_id
      t.string    :basis_for_selection_category
      t.integer   :order
      t.timestamp :created_at
    end

    add_foreign_key "cavc_decision_reasons", "cavc_decision_reasons", column: "parent_decision_reason_id", validate: false
  end
end
