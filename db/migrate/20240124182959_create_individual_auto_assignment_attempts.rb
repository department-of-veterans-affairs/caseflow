class CreateIndividualAutoAssignmentAttempts < Caseflow::Migration
  def change
    create_table :individual_auto_assignment_attempts do |t|
      t.references :user, foreign_key: true, null: false, index: false,
        comment: "Foreign key to users table"
      t.references :correspondence, foreign_key: true, null: false, index: false,
        comment: "Foreign key to correspondences table"
      t.references :batch_auto_assignment_attempt, foreign_key: true, null: false, index: false,
        comment: "Foreign key to batch_auto_assignment_attempts table"
      t.string :status, null: false
      t.datetime :completed_at
      t.datetime :errored_at
      t.datetime :started_at
      t.boolean :nod, null: false, default: false
      t.jsonb :statistics

      t.timestamps
    end

    add_safe_index :individual_auto_assignment_attempts, :user_id, name: "index_iaaa_on_user_id"
    add_safe_index :individual_auto_assignment_attempts, :correspondence_id, name: "index_iaaa_on_correspondence_id"
    add_safe_index :individual_auto_assignment_attempts, :batch_auto_assignment_attempt_id, name: "index_iaaa_on_batch_auto_assignment_attempt_id"
  end
end
