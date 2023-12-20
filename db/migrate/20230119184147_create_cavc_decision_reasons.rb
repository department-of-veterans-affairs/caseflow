class CreateCavcDecisionReasons < Caseflow::Migration
  def change
    create_table :cavc_decision_reasons do |t|
      t.string    :decision_reason, comment: "The reason for the CAVC decision"
      t.integer   :parent_decision_reason_id, comment: "Associates a child decision reason to its parent in this table"
      t.string    :basis_for_selection_category, comment: "The category that the decision reason belongs to. Optional."
      t.integer   :order, comment: "The order that the reasons should display in the UI. Child reasons will be ordered under their parent."
      t.timestamp :created_at
    end

    add_foreign_key "cavc_decision_reasons", "cavc_decision_reasons", column: "parent_decision_reason_id", validate: false
  end
end
