class CreateEtlTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :tasks, comment: "Denormalized Tasks with User/Organization" do |t|
      t.timestamps null: false, comment: "Default created_at/updated_at for the ETL record"
      t.index ["created_at"]
      t.index ["updated_at"]

      # Task attributes
      t.bigint "task_id", null: false, comment: "tasks.id"
      t.bigint "appeal_id", null: false, comment: "tasks.appeal_id"
      t.string "appeal_type", null: false, comment: "tasks.appeal_type"
      t.datetime "assigned_at", comment: "tasks.assigned_at"
      t.bigint "assigned_by_id", comment: "tasks.assigned_by_id"
      t.bigint "assigned_to_id", null: false, comment: "tasks.assigned_to_id"
      t.string "assigned_to_type", null: false, comment: "tasks.assigned_to_type"
      t.datetime "closed_at", comment: "tasks.closed_at"
      t.datetime "task_created_at", comment: "tasks.created_at"
      t.datetime "task_updated_at", comment: "tasks.updated_at"
      t.text "instructions", default: [], array: true, comment: "tasks.instructions"
      t.bigint "parent_id", comment: "tasks.parent_id"
      t.datetime "placed_on_hold_at", comment: "tasks.placed_on_hold_at"
      t.datetime "started_at", comment: "tasks.started_at"
      t.string "task_status", limit: 20, null: false, comment: "tasks.status"
      t.string "task_type", limit: 50, null: false, comment: "tasks.type"

      t.index ["appeal_type", "appeal_id"]
      t.index ["assigned_to_type", "assigned_to_id"]
      t.index ["parent_id"]
      t.index ["task_status"]
      t.index ["task_type"]

      # denormalized attributes (user/organization)
      t.string "assigned_by_user_css_id", limit: 20, comment: "users.css_id"
      t.string "assigned_by_user_full_name", limit: 255, comment: "users.full_name"
      t.string "assigned_by_user_sattyid", limit: 20, comment: "users.sattyid"
      t.string "assigned_to_user_css_id", limit: 20, comment: "users.css_id"
      t.string "assigned_to_user_full_name", limit: 255, comment: "users.full_name"
      t.string "assigned_to_user_sattyid", limit: 20, comment: "users.sattyid"
      t.string "assigned_to_org_name", limit: 255, comment: "organizations.name"
      t.string "assigned_to_org_type", limit: 50, comment: "organizations.type"
    end
  end
end
