class CreateRecordSyncedByJob < ActiveRecord::Migration[5.1]
  def change
    create_table :record_synced_by_jobs do |t|
      t.references :record, :polymorphic => true
      t.datetime :submitted_at
      t.datetime :attempted_at
      t.datetime :processed_at
      t.datetime :last_submitted_at
      t.string :error
      t.string :sync_job_name
    end
  end
end
