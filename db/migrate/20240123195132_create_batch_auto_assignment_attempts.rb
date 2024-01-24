class CreateBatchAutoAssignmentAttempts < ActiveRecord::Migration[5.2]
  def change
    create_table :batch_auto_assignment_attempts do |t|
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
  end
end
