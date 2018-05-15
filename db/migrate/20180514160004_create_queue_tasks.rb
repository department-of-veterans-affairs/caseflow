class CreateQueueTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :tasks do |t|
      t.integer "appeal_id", null: false
      t.integer  "status",  default: 0
      t.text "action_type"
      t.text "instructions"
      t.integer "assigned_to_id"
      t.integer "assigned_by_id"
      t.datetime "assigned_at"
      t.datetime "started_at"
      t.datetime "completed_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
