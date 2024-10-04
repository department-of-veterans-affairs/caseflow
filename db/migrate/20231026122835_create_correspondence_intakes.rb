class CreateCorrespondenceIntakes < Caseflow::Migration
  def change
    create_table :correspondence_intakes do |t|
      t.integer :current_step, comment: "Tracks users progress on intake workflow"
      t.bigint :related_appeals, array: true, comment: "Will be used to populate correspondence_appeals db table"
      t.jsonb :added_tasks, array: true, comment: "Each object in the array will contain all relevant information to create the specific Task for either the Correspondence or the Related Appeal"
      t.datetime :errored_at, comment: "Timestamp of when correspondence intake failed due to error"
      t.string :error_reason, comment: "Exception details of when correspondence intake failed due to error"
      t.datetime :canceled_at, comment: "Timestamp of when user cancelled correspondence intake"
      t.string :canceled_reason, comment: "Details of reason user cancelled correspondence intake"
      t.timestamps

      t.references :user, foreign_key: true, index: false, comment: "Foreign key on users table"
      t.references :correspondence, foreign_key: true, index: false, comment: "Foreign key on correspondences table"
    end
  end
end
