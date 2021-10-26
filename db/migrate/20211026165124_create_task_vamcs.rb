class CreateTaskVamcs < ActiveRecord::Migration[5.2]
  def change
    create_table :task_vamcs do |t|
      t.references :task, index: false, references: :tasks, null: false, foreign_key: { to_table: :tasks }, comment: "References tasks table"
      t.string "vamc", null: false, comment: "VA Medical Center Code associated to an Assess Documentation task assigned to a VISN."
      t.timestamps null: false, comment: "Standard created_at/updated_at timestamps"
    end
  end
end
