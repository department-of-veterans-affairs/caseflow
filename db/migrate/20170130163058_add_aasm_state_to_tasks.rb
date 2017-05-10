class AddAasmStateToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :aasm_state, :string
  end
end
