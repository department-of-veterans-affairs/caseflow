class CreateTasksTable < ActiveRecord::Migration[5.1]
  def change
    create_table :tasks_tables do |t|
      t.integer "appeal_id", null: false
      t.integer " status"
      t.text "type"
      t.text "instructions"
      t.integer "assignee_id"
      t.integer "assignor_id"
      t.datetime "assigned_at"
      t.datetime "started_at"
      t.datetime "completed_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
