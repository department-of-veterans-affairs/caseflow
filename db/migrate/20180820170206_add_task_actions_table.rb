class AddTaskActionsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :task_actions do |t|
      t.string "name", null: false
      t.string "type"
      t.string "status_after_action"
      t.string "child_task_assignee_type"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
