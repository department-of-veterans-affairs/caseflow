class AddTaskIdIndexToClaimEstablishments < Caseflow::Migration
  def change
    add_safe_index :claim_establishments, :task_id
  end
end
