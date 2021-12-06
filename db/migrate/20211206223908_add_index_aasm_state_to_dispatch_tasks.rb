class AddIndexAasmStateToDispatchTasks < Caseflow::Migration
  def change
    add_safe_index :dispatch_tasks, [:aasm_state]
  end
end
