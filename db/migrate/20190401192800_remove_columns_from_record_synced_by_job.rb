class RemoveColumnsFromRecordSyncedByJob < ActiveRecord::Migration[5.1]
  def change
    safety_assured do
      remove_column :record_synced_by_jobs, :submitted_at
      remove_column :record_synced_by_jobs, :attempted_at
      remove_column :record_synced_by_jobs, :last_submitted_at
    end
  end
end
