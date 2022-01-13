class AddTaskIdIndexToClaimEstablishments < Caseflow::Migration
  def change
    change_column_comment :claim_establishments, :task_id, "references dispatch_tasks"

    add_safe_index :claim_establishments, :task_id
  end
end
