class CreateTaskVamcs < Caseflow::Migration
  def change
    create_table :task_vamcs, comment: 'Table to store VAMCs associated by VHA Program Offices to Assess Documentation tasks when assigning to a VISN' do |t|
      t.references :task, index: false, references: :tasks, null: false, foreign_key: { to_table: :tasks }, comment: "References tasks table"
      t.string "vamc_label", null: false, comment: "Label of VA Medical Center Code associated to an Assess Documentation task assigned to a VISN."
      t.timestamps null: false, comment: "Standard created_at/updated_at timestamps"
    end

    add_safe_index :task_vamcs, :vamc_label
  end
end
