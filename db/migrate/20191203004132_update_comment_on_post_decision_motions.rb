class UpdateCommentOnPostDecisionMotions < ActiveRecord::Migration[5.1]
  def change
    change_column_comment(:post_decision_motions, :vacate_type, "Granted motion to vacate can be Straight Vacate, Vacate and Readjudication, or Vacate and De Novo.") 
  end
end
