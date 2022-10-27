class AddIndexAasmStateToDispatchTasks < Caseflow::Migration
  def change
    add_safe_index :dispatch_tasks, [:aasm_state]

    change_column_comment :dispatch_tasks, :aasm_state, "Current task state: unprepared, unassigned, assigned, started, reviewed, completed"
  end
end
