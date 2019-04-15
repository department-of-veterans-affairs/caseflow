class AddBoardGrantLastSubmittedAt < ActiveRecord::Migration[5.1]
  def change
    add_column :board_grant_effectuations, :decision_sync_last_submitted_at, :datetime, comment: "Timestamp for when the the job is eligible to run (can be reset to restart the job)."
  end
end
