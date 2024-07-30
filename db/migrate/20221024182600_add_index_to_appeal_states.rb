class AddIndexToAppealStates < Caseflow::Migration
  def change
    add_safe_index :appeal_states, [:appeal_type, :appeal_id], name: "index_appeal_states_on_appeal_type_and_appeal_id", unique: true
  end
end
