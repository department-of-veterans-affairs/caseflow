class AddAsyncableColumnsToBoardGrantEffectuations < ActiveRecord::Migration[5.1]
  def change
    add_column :board_grant_effectuations, :decision_sync_submitted_at, :datetime
    add_column :board_grant_effectuations, :decision_sync_attempted_at, :datetime
    add_column :board_grant_effectuations, :decision_sync_processed_at, :datetime
    add_column :board_grant_effectuations, :decision_sync_error, :string
  end
end
