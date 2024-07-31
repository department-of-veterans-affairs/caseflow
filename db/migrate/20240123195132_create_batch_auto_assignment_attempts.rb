class CreateBatchAutoAssignmentAttempts < Caseflow::Migration
  def change
    create_table :batch_auto_assignment_attempts do |t|
      t.references :user, foreign_key: true, null: false, index: false,
        comment: "Foreign key to users table"
      t.string :status, null: false
      t.integer :num_packages_assigned
      t.integer :num_packages_unassigned
      t.integer :num_nod_packages_assigned
      t.integer :num_nod_packages_unassigned
      t.datetime :completed_at
      t.datetime :errored_at
      t.datetime :started_at
      t.jsonb :error_info
      t.jsonb :statistics

      t.timestamps
    end

    add_safe_index :batch_auto_assignment_attempts, :user_id, name: "index_baaa_on_user_id"
  end
end
